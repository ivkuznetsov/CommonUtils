import Foundation

public protocol JSONDictionaryItem: Sendable { }

extension NSNull: JSONDictionaryItem { }
extension String: JSONDictionaryItem { }
extension UUID: JSONDictionaryItem { }
extension Int: JSONDictionaryItem { }
extension Double: JSONDictionaryItem { }
extension Float: JSONDictionaryItem { }
extension Decimal: JSONDictionaryItem { }
extension NSNumber: JSONDictionaryItem { }
extension Bool: JSONDictionaryItem { }
extension [any JSONDictionaryItem]: JSONDictionaryItem { }
extension [String: any JSONDictionaryItem]: JSONDictionaryItem { }

public struct JSONDictionary: Sendable, Codable, JSONDictionaryItem, CustomStringConvertible {
    
    public var store: [String: Item] = [:]
    
    public var description: String { store.description }
    
    public enum Item: Sendable, Codable, CustomStringConvertible, JSONDictionaryItem {
        
        case null
        case bool(Bool)
        case integer(Int)
        case double(Double)
        case decimal(Decimal)
        case string(String)
        case uuid(UUID)
        case dictionary(JSONDictionary)
        case array([Item])
        
        public var description: String { "\(value)" }
        
        init(value: Any) throws {
            if let item = value as? Item {
                self = item
            } else if let string = value as? String {
                self = .string(string)
            } else if let bool = value as? Bool {
                self = .bool(bool)
            } else if let int = value as? Int {
                self = .integer(int)
            } else if let double = value as? Double {
                self = .double(double)
            } else if let double = value as? Float {
                self = .double(Double(double))
            } else if let value = value as? JSONDictionary {
                self = .dictionary(value)
            } else if let value = value as? [Any] {
                self = try .array(value.map { try .init(value: $0) })
            } else if let uuid = value as? UUID {
                self = .uuid(uuid)
            } else if let decimal = value as? Decimal {
                self = .decimal(decimal)
            } else if let value = value as? [String: Any] {
                self = try .dictionary(JSONDictionary(value))
            } else {
                throw RunError.custom("Unsupported type")
            }
        }
        
        public var value: any JSONDictionaryItem {
            switch self {
            case .null: NSNull()
            case .string(let string): string
            case .uuid(let uuid): uuid
            case .integer(let val): NSNumber(integerLiteral: val)
            case .double(let val): NSNumber(floatLiteral: val)
            case .decimal(let val): val
            case .dictionary(let object): object
            case .array(let array): array.map { $0.value }
            case .bool(let bool): bool
            }
        }
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()

            if container.decodeNil() {
                self = .null
            } else if let val = try? container.decode(Int.self) {
                self = .integer(val)
            } else if let val = try? container.decode(Double.self) {
                self = .double(val)
            } else if let val = try? container.decode(String.self) {
                self = .string(val)
            } else if let val = try? container.decode(Bool.self) {
                self = .bool(val)
            } else if let val = try? container.decode(Decimal.self) {
                self = .decimal(val)
            } else if let val = try? container.decode([Item].self) {
                self = .array(val)
            } else if let val = try? container.decode(JSONDictionary.self) {
                self = .dictionary(val)
            } else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Invalid JSON value.")
                )
            }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .null: try container.encodeNil()
            case let .array(val): try container.encode(val)
            case let .dictionary(val): try container.encode(val)
            case let .string(val): try container.encode(val)
            case let .integer(val): try container.encode(val)
            case let .decimal(val): try container.encode(val)
            case let .double(val): try container.encode(val)
            case let .bool(val): try container.encode(val)
            case let .uuid(val): try container.encode(val)
            }
        }
    }

    public subscript(key: String) -> (any JSONDictionaryItem)? {
        get { store[key]?.value }
        set {
            if let value = newValue {
                store[key] = try! .init(value: value)
            } else {
                store[key] = nil
            }
        }
    }
    
    public init() { }
    
    public init(from decoder: any Decoder) throws {
        store = try decoder.singleValueContainer().decode([String: Item].self)
    }
        
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(store)
    }
}

extension [String: Any] {
    
    public func asJSON() throws -> JSONDictionary {
        try .init(self)
    }
}

extension JSONDictionary: ExpressibleByDictionaryLiteral {
    
    public init(_ dict: [String: Any]) throws {
        for element in dict {
            store[element.0] = try .init(value: element.1)
        }
    }
    
    public init(_ dict: [String: any JSONDictionaryItem]) {
        for element in dict {
            store[element.0] = try! .init(value: element.1)
        }
    }
    
    public init(dictionaryLiteral elements: (String, any JSONDictionaryItem)...) {
        for element in elements {
            store[element.0] = try! .init(value: element.1)
        }
    }
}
