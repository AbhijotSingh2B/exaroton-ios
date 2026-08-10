import Foundation
import Combine

// MARK: - Debug Logger

enum LogCategory: String, CaseIterable {
    case system = "SYSTEM"
    case network = "NETWORK"
    case websocket = "WEBSOCKET"
    case error = "ERROR"
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let category: LogCategory
    let message: String
}

@MainActor
final class DebugLogger: ObservableObject {
    static let shared = DebugLogger()
    
    @Published private(set) var logs: [LogEntry] = []
    
    private let maxLogs = 300
    
    private init() {}
    
    func log(_ message: String, category: LogCategory = .system) {
        let entry = LogEntry(category: category, message: message)
        
        appendLog(entry)
    }
    
    private func appendLog(_ entry: LogEntry) {
        logs.append(entry)
        if logs.count > maxLogs {
            logs.removeFirst(logs.count - maxLogs)
        }
        
        // Also print to standard console for Xcode debugging
        print("[\(entry.category.rawValue)] \(entry.message)")
    }
    
    func clear() {
        logs.removeAll()
    }
}
