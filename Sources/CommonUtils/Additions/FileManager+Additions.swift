//
//  FileManager+Additions.swift
//

import Foundation

public extension FileManager {
    
    private static func dir(_ searchPath: SearchPathDirectory) -> String {
        let dir = NSSearchPathForDirectoriesInDomains(searchPath, .userDomainMask, true)[0] + "/" + Bundle.main.bundleIdentifier!
        
        if !FileManager.default.fileExists(atPath: dir) {
            try! FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
        }
        return dir
    }
    
    static var applicationSupportDirectory: String { dir(.applicationSupportDirectory) }
    
    static var applicationCacheDirectory: String { dir(.cachesDirectory) }
    
    static var applicationDocumentsDirectory: String { dir(.documentDirectory) }
}
