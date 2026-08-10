import Foundation
import Combine

// MARK: - WebSocket Message Models

struct WSMessage: Decodable {
    let type: String
    let stream: String?
    let data: WSData?

    enum WSData: Decodable {
        case string(String)
        case server(ExarotonServer)
        case stats(WSStats)
        case heap(WSHeap)
        case tick(WSTick)
        case raw([String: AnyCodable])

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let s = try? container.decode(String.self) { self = .string(s); return }
            if let server = try? container.decode(ExarotonServer.self) { self = .server(server); return }
            if let stats = try? container.decode(WSStats.self) { self = .stats(stats); return }
            if let heap = try? container.decode(WSHeap.self) { self = .heap(heap); return }
            if let tick = try? container.decode(WSTick.self) { self = .tick(tick); return }
            self = .string("")
        }
    }
}

struct WSStats: Decodable {
    struct Memory: Decodable { let percent: Double; let usage: Int }
    let memory: Memory
}

struct WSHeap: Decodable { let usage: Int }
struct WSTick: Decodable { let averageTickTime: Double }

// Needed for heterogeneous JSON decoding
struct AnyCodable: Codable {
    let value: Any
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) { value = v }
        else if let v = try? container.decode(Int.self) { value = v }
        else if let v = try? container.decode(Double.self) { value = v }
        else if let v = try? container.decode(String.self) { value = v }
        else { value = "" }
    }
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

// MARK: - WebSocket Stream Types

enum WSStream: String {
    case status  = "status"
    case console = "console"
    case stats   = "stats"
    case heap    = "heap"
    case tick    = "tick"
}

// MARK: - Server WebSocket Manager

@MainActor
final class ServerWebSocket: ObservableObject {

    // MARK: Published State
    @Published var serverStatus: ServerStatus = .offline
    @Published var consoleLines: [String] = []
    @Published var ramPercent: Double = 0
    @Published var heapUsageBytes: Int = 0
    @Published var averageTickTime: Double = 0
    @Published var isConnected: Bool = false

    // MARK: Internal

    private var task: URLSessionWebSocketTask?
    private var pingTimer: Timer?
    private let serverId: String
    private let wsURL: URL
    private var subscribedStreams: Set<WSStream> = []
    
    // Throttling
    private let lineSubject = PassthroughSubject<String, Never>()
    private var lineCancellable: AnyCancellable?

    // MARK: Notification Callback

    var onStatusChange: ((ServerStatus, ServerStatus) -> Void)?  // (old, new)

    // MARK: Init

    init(serverId: String, wsURL: URL) {
        self.serverId = serverId
        self.wsURL = wsURL
        
        lineCancellable = lineSubject
            .collect(.byTime(DispatchQueue.main, .milliseconds(200)))
            .sink { [weak self] lines in
                guard let self = self, !lines.isEmpty else { return }
                self.consoleLines.append(contentsOf: lines)
                if self.consoleLines.count > 2000 {
                    self.consoleLines.removeFirst(self.consoleLines.count - 2000)
                }
            }
    }

    // MARK: Connect / Disconnect

    func connect() {
        let request = URLRequest(url: wsURL)
        // Additional header auth as fallback
        let task = URLSession.shared.webSocketTask(with: request)
        self.task = task
        
        DebugLogger.shared.log("Connecting to WS...", category: .websocket)
        
        task.resume()
        receiveLoop()
        startPing()
    }

    func disconnect() {
        DebugLogger.shared.log("Disconnecting WS...", category: .websocket)
        pingTimer?.invalidate()
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
        isConnected = false
    }

    // MARK: Subscribe to Streams

    func subscribe(to stream: WSStream, tail: Int? = nil) {
        guard !subscribedStreams.contains(stream) else { return }
        subscribedStreams.insert(stream)

        var payload: [String: Any] = ["stream": stream.rawValue, "type": "start"]
        if stream == .console, let tail = tail {
            payload["data"] = ["tail": tail]
        }
        send(payload)
    }

    func unsubscribe(from stream: WSStream) {
        subscribedStreams.remove(stream)
        send(["stream": stream.rawValue, "type": "stop"])
    }

    // MARK: Send Command

    func sendCommand(_ command: String) {
        send(["stream": "console", "type": "command", "data": command])
    }

    // MARK: Private

    private func send(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let text = String(data: data, encoding: .utf8) else { return }
        
        DebugLogger.shared.log("-> \(text)", category: .websocket)
        
        task?.send(.string(text)) { _ in }
    }

    private func receiveLoop() {
        task?.receive { [weak self] result in
            guard let self else { return }
            switch result {
            case .success(let message):
                Task { @MainActor in
                    self.handle(message: message)
                    self.receiveLoop()
                }
            case .failure:
                Task { @MainActor in
                    self.isConnected = false
                }
            }
        }
    }

    private func handle(message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            // Don't log tick payloads since they spam the console every second
            if !text.contains("\"type\":\"tick\"") {
                DebugLogger.shared.log("<- \(text)", category: .websocket)
            }
            guard let data = text.data(using: .utf8) else { return }
            handleData(data)
        case .data(let data):
            handleData(data)
        @unknown default: break
        }
    }

    private func handleData(_ data: Data) {
        guard
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let type = json["type"] as? String
        else { return }

        let stream = json["stream"] as? String

        switch type {
        case "ready":
            isConnected = true

        case "status" where stream == "status":
            if let dataDict = json["data"],
               let serverData = try? JSONSerialization.data(withJSONObject: dataDict),
               let server = try? JSONDecoder().decode(ExarotonServer.self, from: serverData) {
                let old = serverStatus
                serverStatus = server.status
                if old != server.status {
                    onStatusChange?(old, server.status)
                }
            }

        case "line" where stream == "console":
            if let line = json["data"] as? String {
                lineSubject.send(line)
            }

        case "stats" where stream == "stats":
            if let dataDict = json["data"] as? [String: Any],
               let mem = dataDict["memory"] as? [String: Any],
               let pct = mem["percent"] as? Double {
                ramPercent = pct
            }

        case "heap" where stream == "heap":
            if let dataDict = json["data"] as? [String: Any],
               let usage = dataDict["usage"] as? Int {
                heapUsageBytes = usage
            }

        case "tick" where stream == "tick":
            if let dataDict = json["data"] as? [String: Any],
               let avg = dataDict["averageTickTime"] as? Double {
                averageTickTime = avg
            }

        default: break
        }
    }

    private func startPing() {
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.task?.sendPing { _ in }
            }
        }
    }
}
