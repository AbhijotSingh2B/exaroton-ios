import Foundation

// MARK: - File / Directory Info

struct FileInfo: Codable, Identifiable {
    let path: String
    let name: String
    let isTextFile: Bool
    let isConfigFile: Bool
    let isDirectory: Bool
    let isLog: Bool
    let children: [FileInfo]?
    let size: Int?

    var id: String { path }
}
