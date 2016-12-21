//
//  Helpers.swift
//  Centa
//
//  Created by Shawn Gong on 10/31/16.
//
//

import Foundation
import HTTP

// MARK: Short UID

func dbContainsUid(_ uid: String) -> Bool {
    do {
        if let _ = try Trip.query().filter("uid", uid).first() {
            return true
        }
        if let _ = try User.query().filter("uid", uid).first() {
            return true
        }
    } catch {
        return false
    }
    
    return false
}

// 56 billion possibilities - should be sufficient for global use
public func genUid(len: Int = 6) -> String {
    var uid = ""
    repeat {
        uid = randomStringWithLength(len: len)
    } while dbContainsUid(uid)
    return uid
}

// It chooses from 26 + 26 + 10 = 62 chars, so 62^len in possible outcomes.
// e.g. 62^8 = 218,340,105,584,896
// 62^16 = 4.76 e+28
public func randomStringWithLength(len: Int) -> String {
    
    let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    
    let randomString : NSMutableString = NSMutableString(capacity: len)
    
    for _ in  0..<len {
        let length = UInt32 (letters.length)
        let rand = arc4random_uniform(length)
        randomString.appendFormat("%C", letters.character(at: Int(rand)))
    }
    
    return randomString as String
}

