//
//  Codable+Additions.swift
//

import Foundation
import Combine

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
    
    func toData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try toData(encoder)
    }
        
    func toData<E: TopLevelEncoder>(_ encoder: E) throws -> E.Output {
        try encoder.encode(self)
    }
}

public extension Decodable {
    
    static func decode(_ data: Data) throws -> Self {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(self, from: data)
    }
    
    static func decode<D: TopLevelDecoder>(_ data: D.Input, decoder: D) throws -> Self {
        return try decoder.decode(self, from: data)
    }
    
    static func decode(_ dict: [String : Any]) throws -> Self {
        let data = try Foundation.JSONSerialization.data(withJSONObject: dict, options: [])
        return try decode(data)
    }
}
