//
//  Person.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit

struct Person: Identifiable {

    /// Properties
    public let id = UUID()
    let name: String
//    var coffeesOwed: [String: Int] = [:]
    var associatedRecord: CKRecord
    
    /// Coding Key
    private enum CodingKeys: String, CodingKey {
        case name, isPresent, coffeesOwed, userRecordName, associatedRecord
    }
    
    /// Initializer from cloudkit
    init(name: String, associatedRecord: CKRecord) {
        self.name = name
        self.associatedRecord = associatedRecord
    }
    
    /// initializer from new name. creates a ckrecord
    init(name: String, participantType: ParticipantType) {
        self.name = name
        let record = CKRecord(recordType: participantType.rawValue, recordID: CKRecord.ID(recordName: UUID().uuidString, zoneID: Repository.shared.currentZone.zoneID))
        record["name"] = name
        self.associatedRecord = record
    }
    
    /// empty person
    init() {
        self.name = "nobody"
        let record = CKRecord(recordType: ParticipantType.root.rawValue, recordID: CKRecord.ID(recordName: "nobody", zoneID: Repository.shared.currentZone.zoneID))
        associatedRecord = record
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
