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
    
    func write(to url: URL, dates: JSONEncoder.DateEncodingStrategy = .iso8601) throws {
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = dates
        try toData(encoder).write(to: url, options: [.atomic])
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
    
    init(contentsOf url: URL, dates: JSONDecoder.DateDecodingStrategy = .iso8601) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dates
        self = try .decode(data, decoder: decoder)
    }
}
