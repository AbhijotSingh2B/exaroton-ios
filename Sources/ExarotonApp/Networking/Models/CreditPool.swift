import Foundation

// MARK: - Credit Pool

struct CreditPool: Codable, Identifiable {
    let id: String
    let name: String
    let credits: Double
    let servers: [ExarotonServer]?
    let members: [PoolMember]?
}

struct PoolMember: Codable, Identifiable {
    let uuid: String
    let name: String
    var id: String { uuid }
}
