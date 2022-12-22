//
//  Date+Additions.swift
//

import Foundation

public extension String {
    
    func date(format: String) -> Date? {
        Date.formatter(format: format, local: false).date(from: self)
    }
    
    func localDate(format: String) -> Date? {
        Date.formatter(format: format, local: true).date(from: self)
    }
}

public extension Date {
    
    fileprivate static func formatter(format: String, local: Bool) -> DateFormatter {
        let formatter = DateFormatter()
        if local {
            formatter.locale = Locale(identifier: "en_US_POSIX")
        }
        formatter.dateFormat = format
        return formatter
    }
    
    func string(format: String) -> String {
        Date.formatter(format: format, local: false).string(from: self)
    }
    
    func localString(format: String) -> String {
        Date.formatter(format: format, local: true).string(from: self)
    }
    
    var withoutTime: Date {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.year, .month, .day], from: self)
        
        components.hour = 0
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone.current
        
        return calendar.date(from: components)!
    }
    
    private var components: DateComponents {
        Calendar(identifier: .gregorian).dateComponents([.year, .weekOfYear, .month, .weekOfMonth, .day, .hour, .minute, .second], from: self)
    }
    
    var weekDay: Int { components.weekday! }
    
    var day: Int { components.day! }
    
    var week: Int { components.weekOfYear! }
    
    var month: Int { components.month! }
    
    var year: Int { components.year! }
    
    var hour: Int { components.hour! }
    
    var minute: Int { components.minute! }
    
    var second: Int { components.second! }
}
