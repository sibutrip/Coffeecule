//
//  Repository.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit

enum RecordZones: String {
    case Transactions = "TransactionsTest"
    case People = "PeopleTest"
    func callAsFunction() -> CKRecordZone {
        return CKRecordZone(zoneName: self.rawValue)
    }
}

struct Repository {
    let url: URL
    let dummyUrl: URL
    let peopleUrl: URL
    let dummyPeopleUrl: URL
    var ckShare: CKShare?
    
    /// Use the specified iCloud container ID, which should also be present in the entitlements file.
    lazy var container = CKContainer(identifier: "iCloud.com.CoryTripathy.Coffeecule")
    
    /// This project uses the user's private database.
    lazy var database = container.privateCloudDatabase
    
    /// Sharing requires using a custom record zone.
    let recordZone = CKRecordZone(zoneName: "TransactionsTest")
    let recordType = "TransactionsTest"
    
    private init() {
        guard let url = try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("cachedTransactions.json") else {
            fatalError("cannot write cachedTransactions")
        }
        self.url = url
        
        guard let dummyUrl = try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("cachedDummyTransactions.json") else {
            fatalError("cannot write cachedDummyTransactions")
        }
        self.dummyUrl = dummyUrl
        
        guard let peopleUrl = try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("people.json") else {
            fatalError("cannot write people")
        }
        self.peopleUrl = peopleUrl
        
        guard let dummyPeopleUrl = try? FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            .appendingPathComponent("dummyPeople.json") else {
            fatalError("cannot write people")
        }
        self.dummyPeopleUrl = dummyPeopleUrl
        
    }
    
    static var shared = Repository()
}
