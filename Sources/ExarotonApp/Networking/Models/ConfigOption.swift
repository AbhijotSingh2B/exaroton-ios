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

struct ExarotonConfigOptionData: Codable {
    let value: String?
    let type: String?
    let label: String?
    let documentation: String?
    let options: [String]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Exaroton returns values as int, bool, or string. Decode to string.
        if let intVal = try? container.decode(Int.self, forKey: .value) {
            value = String(intVal)
        } else if let boolVal = try? container.decode(Bool.self, forKey: .value) {
            value = String(boolVal)
        } else if let strVal = try? container.decode(String.self, forKey: .value) {
            value = strVal
        } else {
            value = ""
        }
        
        type = try? container.decode(String.self, forKey: .type)
        label = try? container.decode(String.self, forKey: .label)
        documentation = try? container.decode(String.self, forKey: .documentation)
        options = try? container.decode([String].self, forKey: .options)
    }

    enum CodingKeys: String, CodingKey {
        case value, type, label, documentation, options
    }
}
