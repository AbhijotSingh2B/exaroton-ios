import Foundation

// MARK: - Exaroton REST Client

enum ExarotonAPIError: LocalizedError {
    case noActiveAccount
    case httpError(Int)
    case apiError(String)
    case decodingError(Error)
    case unknown

    var errorDescription: String? {
        switch self {
        case .noActiveAccount:      return "No API token set. Please sign in."
        case .httpError(let code):  return "HTTP error \(code)"
        case .apiError(let msg):    return msg
        case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
        case .unknown:              return "Unknown error"
        }
    }
}

actor ExarotonClient {

    private let baseURL = URL(string: "https://api.exaroton.com/v1")!
    private let accountManager: AccountManager
    private let session: URLSession

    init(accountManager: AccountManager) {
        self.accountManager = accountManager
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Encodable? = nil
    ) async throws -> T {
        guard let token = await accountManager.activeAccount?.token else {
            throw ExarotonAPIError.noActiveAccount
        }

        var url = baseURL.appendingPathComponent(path)
        // Ensure trailing slash for Exaroton API convention
        if !url.absoluteString.hasSuffix("/") {
            url = URL(string: url.absoluteString + "/")!
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        await DebugLogger.shared.log("\(method) \(path)", category: .network)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ExarotonAPIError.unknown }
        
        await DebugLogger.shared.log("\(method) \(path) -> \(http.statusCode)", category: .network)
        
        guard (200..<300).contains(http.statusCode) else {
            await DebugLogger.shared.log("HTTP Error \(http.statusCode) for \(path)", category: .error)
            throw ExarotonAPIError.httpError(http.statusCode) 
        }

        do {
            let wrapper = try JSONDecoder().decode(APIResponse<T>.self, from: data)
            if !wrapper.success, let msg = wrapper.error {
                throw ExarotonAPIError.apiError(msg)
            }
            guard let result = wrapper.data else { throw ExarotonAPIError.unknown }
            return result
        } catch let err as ExarotonAPIError {
            throw err
        } catch {
            throw ExarotonAPIError.decodingError(error)
        }
    }

    // MARK: - Account

    func getAccount() async throws -> ExarotonAccountInfo {
        return try await request(path: "account")
    }

    // MARK: - Servers

    func getServers() async throws -> [ExarotonServer] {
        struct ServersWrapper: Decodable { let servers: [ExarotonServer] }
        return try await request(path: "servers")
    }

    func getServer(id: String) async throws -> ExarotonServer {
        return try await request(path: "servers/\(id)")
    }

    // MARK: - Server Actions

    func startServer(id: String) async throws {
        let _: EmptyData? = try? await request(path: "servers/\(id)/start")
    }

    func stopServer(id: String) async throws {
        let _: EmptyData? = try? await request(path: "servers/\(id)/stop")
    }

    func restartServer(id: String) async throws {
        let _: EmptyData? = try? await request(path: "servers/\(id)/restart")
    }

    // MARK: - Command

    struct CommandBody: Encodable { let command: String }

    func executeCommand(serverId: String, command: String) async throws {
        let _: EmptyData? = try? await request(
            path: "servers/\(serverId)/command",
            method: "POST",
            body: CommandBody(command: command)
        )
    }

    // MARK: - RAM

    func getRAM(serverId: String) async throws -> Int {
        let result: ServerRAM = try await request(path: "servers/\(serverId)/ram")
        return result.ram
    }

    struct RAMBody: Encodable { let ram: Int }

    func setRAM(serverId: String, ram: Int) async throws {
        let _: EmptyData? = try? await request(
            path: "servers/\(serverId)/ram",
            method: "POST",
            body: RAMBody(ram: ram)
        )
    }

    // MARK: - MOTD

    func getMOTD(serverId: String) async throws -> String {
        let result: ServerMOTD = try await request(path: "servers/\(serverId)/motd")
        return result.motd
    }

    struct MOTDBody: Encodable { let motd: String }

    func setMOTD(serverId: String, motd: String) async throws {
        let _: EmptyData? = try? await request(
            path: "servers/\(serverId)/motd",
            method: "POST",
            body: MOTDBody(motd: motd)
        )
    }

    // MARK: - Logs

    func getLogs(serverId: String) async throws -> String {
        let result: ServerLog = try await request(path: "servers/\(serverId)/logs")
        return result.content
    }

    func shareLogs(serverId: String) async throws -> LogUploadResult {
        return try await request(path: "servers/\(serverId)/logs/share")
    }

    // MARK: - Player Lists

    func getAvailablePlayerLists(serverId: String) async throws -> [String] {
        return try await request(path: "servers/\(serverId)/playerlists")
    }

    func getPlayerList(serverId: String, list: String) async throws -> [String] {
        return try await request(path: "servers/\(serverId)/playerlists/\(list)")
    }

    func addPlayersToList(serverId: String, list: String, players: [String]) async throws {
        let _: EmptyData? = try? await request(
            path: "servers/\(serverId)/playerlists/\(list)",
            method: "PUT",
            body: players
        )
    }

    func removePlayersFromList(serverId: String, list: String, players: [String]) async throws {
        let _: EmptyData? = try? await request(
            path: "servers/\(serverId)/playerlists/\(list)",
            method: "DELETE",
            body: players
        )
    }

    // MARK: - Files

    func getFileInfo(serverId: String, path: String = "") async throws -> FileInfo {
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        return try await request(path: "servers/\(serverId)/files/info/\(encodedPath)")
    }

    func getFileData(serverId: String, path: String) async throws -> String {
        guard let token = await accountManager.activeAccount?.token else {
            throw ExarotonAPIError.noActiveAccount
        }
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        let url = baseURL.appendingPathComponent("servers/\(serverId)/files/data/\(encodedPath)/")
        var req = URLRequest(url: url)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await session.data(for: req)
        return String(data: data, encoding: .utf8) ?? ""
    }

    func writeFileData(serverId: String, path: String, content: String) async throws {
        guard let token = await accountManager.activeAccount?.token else {
            throw ExarotonAPIError.noActiveAccount
        }
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        let url = baseURL.appendingPathComponent("servers/\(serverId)/files/data/\(encodedPath)/")
        var req = URLRequest(url: url)
        req.httpMethod = "PUT"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = content.data(using: .utf8)
        _ = try await session.data(for: req)
    }

    func deleteFile(serverId: String, path: String) async throws {
        guard let token = await accountManager.activeAccount?.token else {
            throw ExarotonAPIError.noActiveAccount
        }
        let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
        let url = baseURL.appendingPathComponent("servers/\(serverId)/files/data/\(encodedPath)/")
        var req = URLRequest(url: url)
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try await session.data(for: req)
    }

    // MARK: - Config Files

    func getConfigOptions(serverId: String) async throws -> [ConfigOption] {
        let dict: [String: ExarotonConfigOptionData] = try await request(path: "servers/\(serverId)/options")
        return dict.map { key, data in
            ConfigOption(
                key: key,
                value: data.value ?? "",
                valueType: data.type,
                label: data.label,
                documentation: data.documentation,
                options: data.options
            )
        }.sorted { $0.key < $1.key }
    }

    struct ConfigUpdateBody: Encodable { let options: [String: String] }

    func updateConfigOptions(serverId: String, options: [String: String]) async throws {
        let _: EmptyData? = try? await request(
            path: "servers/\(serverId)/options",
            method: "POST",
            body: ConfigUpdateBody(options: options)
        )
    }

    // MARK: - Credit Pools

    func getCreditPools() async throws -> [CreditPool] {
        return try await request(path: "billing/pools")
    }

    // MARK: - WebSocket URL Helper

    func webSocketRequest(serverId: String) async -> URLRequest? {
        guard let token = await accountManager.activeAccount?.token else { return nil }
        var components = URLComponents()
        components.scheme = "wss"
        components.host = "api.exaroton.com"
        components.path = "/v1/servers/\(serverId)/websocket"
        components.queryItems = [URLQueryItem(name: "authorization", value: token)]
        guard let url = components.url else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
}
