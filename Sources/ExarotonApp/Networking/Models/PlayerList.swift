import Foundation

// MARK: - Player List

struct PlayerList: Codable, Identifiable {
    let name: String
    let entries: [String]

    var id: String { name }
}

struct PlayerListName: Codable, Identifiable {
    let name: String
    var id: String { name }
}
