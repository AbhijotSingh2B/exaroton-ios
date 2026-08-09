import Foundation

// MARK: - Server Status

enum ServerStatus: Int, Codable, CustomStringConvertible {
    case offline       = 0
    case online        = 1
    case starting      = 2
    case stopping      = 3
    case restarting    = 4
    case saving        = 5
    case loading       = 6
    case crashed       = 7
    case pending       = 8
    case transferring  = 9
    case preparing     = 10

    var description: String {
        switch self {
        case .offline:      return "Offline"
        case .online:       return "Online"
        case .starting:     return "Starting"
        case .stopping:     return "Stopping"
        case .restarting:   return "Restarting"
        case .saving:       return "Saving"
        case .loading:      return "Loading"
        case .crashed:      return "Crashed"
        case .pending:      return "Pending"
        case .transferring: return "Transferring"
        case .preparing:    return "Preparing"
        }
    }

    var isTransitioning: Bool {
        switch self {
        case .starting, .stopping, .restarting, .saving, .loading, .pending, .transferring, .preparing:
            return true
        default:
            return false
        }
    }

    var isOnline: Bool { self == .online }
    var isOffline: Bool { self == .offline }
}

// MARK: - Players

struct ServerPlayers: Codable {
    let max: Int
    let count: Int
    let list: [String]
}

// MARK: - Software

struct ServerSoftware: Codable, Identifiable {
    let id: String
    let name: String
    let version: String
}

// MARK: - Server

struct ExarotonServer: Codable, Identifiable {
    let id: String
    let name: String
    let address: String
    let motd: String
    let status: ServerStatus
    let host: String?
    let port: Int?
    let players: ServerPlayers
    let software: ServerSoftware?
    let shared: Bool

    enum CodingKeys: String, CodingKey {
        case id, name, address, motd, status, host, port, players, software, shared
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id       = try container.decode(String.self, forKey: .id)
        name     = try container.decode(String.self, forKey: .name)
        address  = try container.decode(String.self, forKey: .address)
        motd     = try container.decodeIfPresent(String.self, forKey: .motd) ?? ""
        let rawStatus = try container.decode(Int.self, forKey: .status)
        status   = ServerStatus(rawValue: rawStatus) ?? .offline
        host     = try container.decodeIfPresent(String.self, forKey: .host)
        port     = try container.decodeIfPresent(Int.self, forKey: .port)
        players  = try container.decode(ServerPlayers.self, forKey: .players)
        software = try container.decodeIfPresent(ServerSoftware.self, forKey: .software)
        shared   = try container.decodeIfPresent(Bool.self, forKey: .shared) ?? false
    }
}

// MARK: - RAM

struct ServerRAM: Codable {
    let ram: Int // in GB
}

// MARK: - MOTD

struct ServerMOTD: Codable {
    let motd: String
}
