import Foundation

// MARK: - Config Option

struct ConfigOption: Codable, Identifiable {
    let key: String
    let value: String
    let valueType: String?
    let label: String?
    let documentation: String?
    let options: [String]?

    var id: String { key }

    enum CodingKeys: String, CodingKey {
        case key, value, valueType = "type", label, documentation, options
    }
}

struct ConfigFile: Codable {
    let type: String
    let options: [ConfigOption]
}
