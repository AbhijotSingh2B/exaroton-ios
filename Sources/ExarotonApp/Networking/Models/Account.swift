import Foundation

// MARK: - Exaroton Account Model

struct ExarotonAccountInfo: Decodable, Identifiable {
    let id: String?
    let name: String
    let email: String
    let verified: Bool
    let credits: Double
}
