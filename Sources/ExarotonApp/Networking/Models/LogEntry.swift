import Foundation

// MARK: - Log Entry

struct ServerLog: Decodable {
    let content: String
}

// MARK: - mclo.gs Upload Result

struct LogUploadResult: Decodable {
    let id: String?
    let url: String
}
