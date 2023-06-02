//
//  Person.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit

public struct Person: Identifiable {

    /// Properties
    public let id = UUID()
    let name: String
    var isPresent = true
    var coffeesOwed: [String: Int] = [:]
    var associatedRecord: CKRecord?
    var userRecordName: String //CKRecord.ID.recordName
    
    /// Coding Key
    private enum CodingKeys: String, CodingKey {
        case name, isPresent, coffeesOwed, userRecordName, associatedRecord
    }
    
    /// Initializer from onboarding
//    init(name: String, userRecordName: String) {
//        self.name = name
//        self.userRecordName = userRecordName
//    }
    
    /// Initializer from cloudkit, onboarding
    init(name: String, associatedRecord: CKRecord? = nil) {
        self.name = name
        self.associatedRecord = associatedRecord
        if let record = associatedRecord {
            self.userRecordName = record[name] as! String
        } else {
            self.userRecordName = ""
        }
    }
    
    /// Initializer when decoding from JSON
    //TODO: encode ckrecord somehow?
//    public init(from decoder: Decoder) throws {
//        let values = try decoder.container(keyedBy: CodingKeys.self)
//        name = try values.decode(String.self, forKey: .name)
//        isPresent = try values.decode(Bool.self, forKey: .isPresent)
//        coffeesOwed = try values.decode([String: Int].self, forKey: .coffeesOwed)
//        associatedRecord = try values.decode(CKRecord.self, forKey: .associatedRecord)
//        userRecordName = try values.decode(String.self, forKey: .userRecordName)
//    }
}

/// Need for displayedDebts dictionary in ViewModel
extension Person: Hashable {
    public static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.name == rhs.name
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
    }
}

extension Person: Comparable {
    public static func < (lhs: Person, rhs: Person) -> Bool {
        lhs.name < rhs.name
    }
}
