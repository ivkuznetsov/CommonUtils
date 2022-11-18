//
//  Codable+Additions.swift
//

import Foundation

public extension Data {
    
    func toDict() throws -> [String : Any] {
        if let dict = try JSONSerialization.jsonObject(with: self, options: []) as? [String : Any] {
            return dict
        }
        throw RunError.custom("Invalid return type of decoded data")
    }
}

public extension Encodable {
    
    func toDict() throws -> [String : Any] {
        try toData().toDict()
    }
    
    func toData(_ encoder: JSONEncoder = JSONEncoder()) throws -> Data {
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

public extension Decodable {
    
    static func decode(_ data: Data, decoder: JSONDecoder = JSONDecoder()) throws -> Self {
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(self, from: data)
    }
    
    static func decode(_ dict: [String : Any]) throws -> Self {
        let data = try Foundation.JSONSerialization.data(withJSONObject: dict, options: [])
        return try decode(data)
    }
}
