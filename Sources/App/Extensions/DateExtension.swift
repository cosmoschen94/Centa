//
//  DateExtension.swift
//  Centa
//
//  Created by Shawn Gong on 12/30/16.
//
//

import Foundation

extension Date {
    // Could also use ISO8601DateFormatter in iOS & macOS
    static let iso8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        // formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mmZZZZZ"
        return formatter
    }()
    
    var iso8601: String {
        return Date.iso8601Formatter.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return Date.iso8601Formatter.date(from: self)
    }
}
