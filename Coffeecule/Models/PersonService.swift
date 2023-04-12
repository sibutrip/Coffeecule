//
//  PersonService.swift
//  SharedContainer
//
//  Created by Cory Tripathy on 3/29/23.
//

import Foundation
import SwiftUI
import CloudKit

class PersonService: ObservableObject {
    
    // RECORDS AND SHARES
    public var rootRecord: CKRecord? = nil
    public var rootShare: CKShare? = nil
    private let rootRecordName = "rootRecord"
    private let participantRecordName = "participantRecord"
    private let repository = Repository.shared
    
    // MARK: - PRIVATE METHODS
    
    // RECORDS METHODS
    public func fetchOrCreateShare() async {
        func fetchShare() async -> CKShare? {
            var share: CKShare? = nil
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "cloudkit.share", predicate: predicate)
            let (results, _) = try! await repository.database.records(matching: query, inZoneWith: repository.coffeeculeRecordZone.zoneID,desiredKeys: nil, resultsLimit: 10)
            for (_, result) in results {
                switch result {
                case .success(let record):
                    share = record as! CKShare?
                    return share
                case .failure(let error):
                    print(error)
                }
            }
            return share
        }
        var share = await fetchShare()
        if share == nil {
            share = await createRootShare()
        }
        self.rootShare = share
    }
    
    private func createRootShare() async -> CKShare {
        let share = CKShare(recordZoneID: repository.coffeeculeRecordZone.zoneID)
        share.publicPermission = .readWrite
        share[CKShare.SystemFieldKey.title] = "Person"
        let resultTest = try! await self.repository.database.modifyRecords(saving: [share], deleting: [])
        return share
    }
    
    public func createRootRecord(for name: String) throws -> CKRecord {
        enum RootRecordError: Error {
            case nameIsEmpty, rootRecordAlreadyExists
        }
        if name.isEmpty { throw RootRecordError.nameIsEmpty }
        if self.rootRecord != nil { throw RootRecordError.rootRecordAlreadyExists }
        let record = CKRecord(recordType: rootRecordName, recordID: CKRecord.ID(recordName: name, zoneID: repository.coffeeculeRecordZone.zoneID))
        self.rootRecord = record
        return record
    }
    
    public func createParticipantRecord(for name: String) async -> CKRecord {
        let zone = try! await repository.container.sharedCloudDatabase.allRecordZones()[0]
        let record = CKRecord(recordType: participantRecordName, recordID: CKRecord.ID(recordName: name, zoneID: zone.zoneID))
        return record
    }
    
    public func saveSharedRecord(_ record: CKRecord) async {
        do {
            let result = try await Repository.shared.container.sharedCloudDatabase.modifyRecords(saving: [record], deleting: [])
            print(result.saveResults)
        } catch {
            debugPrint(error)
        }
    }
    
    public func savePrivateRecord(_ record: CKRecord) async {
        do {
            let result = try await self.repository.database.modifyRecords(saving: [record], deleting: [])
        } catch {
            debugPrint(error)
        }
    }
    
    /// fetches from private container
    public func fetchPrivatePeople() async -> [CKRecord]{
        var records = [CKRecord]()
        let predicate = NSPredicate(value: true)
        
        let queries: [CKQuery] = [rootRecordName,participantRecordName].map {
            CKQuery(recordType: $0, predicate: predicate)
        }
        
        do {
            for query in queries {
                let (results, _) = try await self.repository.database.records(matching: query, inZoneWith: repository.coffeeculeRecordZone.zoneID,desiredKeys: nil, resultsLimit: 100)
                for (_, result) in results {
                    switch result {
                    case .success(let record):
                        records.append(record)
                        if query.recordType == rootRecordName {
                            self.rootRecord = record
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        } catch {
            print(error)
        }
        return records
    }
    
    /// fetches from shared container
    public func fetchRecords(scope: CKDatabase.Scope) async -> ([CKRecord], [CKRecord], CKShare?) {
//        let databases = [repository.container.database(with: .shared), repository.container.database(with: .private)]
        var people: [CKRecord] = []
        var transactions: [CKRecord] = []
        var share: CKShare? = nil
        
        @Sendable func recordsInZone(_ zone: CKRecordZone, scope: CKDatabase.Scope) async throws -> ([CKRecord], [CKRecord], CKShare?) {
            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil
            var people: [CKRecord] = []
            var transactions: [CKRecord] = []
            var share: CKShare? = nil
            
            while awaitingChanges {
                let zoneChanges = try await Repository.shared.container.database(with: scope).recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
                let receivedRecords = zoneChanges.modificationResultsByID.values
                    .compactMap { try? $0.get().record }
                awaitingChanges = zoneChanges.moreComing
                nextChangeToken = zoneChanges.changeToken
                for record in receivedRecords {
                    if record.recordType == rootRecordName || record.recordType == participantRecordName {
                        people.append(record)
                    } else if record.recordType == "transaction" {
                        transactions.append(record)
                    } else if record.recordType == "cloudkit.share" {
                        if let recievedShare = record as? CKShare {
                            share = recievedShare
                        }
                    }
                }
            }
            return (people, transactions, share)
        }
        
        do {
            async let sharedZones = try repository.container.sharedCloudDatabase.allRecordZones()
            async let privateZones = try repository.container.privateCloudDatabase.allRecordZones()
            let zones = try await sharedZones + privateZones
            
            // Using this task group, fetch each zone's contacts in parallel.
            try await withThrowingTaskGroup(of: ([CKRecord], [CKRecord], CKShare?).self) { group in
                for zone in zones {
                    group.addTask {
                        try await recordsInZone(zone, scope: scope)
                    }
                }
                
                // As each result comes back, append it to a combined array to finally return.
                for try await (returnedPeople, returnedTransactions, returnedShare) in group {
                    people.append(contentsOf: returnedPeople)
                    transactions.append(contentsOf: returnedTransactions)
                    share = returnedShare
                }
            }
            return (people, transactions, share)
        } catch {
            debugPrint(error)
            return([], [], nil)
        }
    }
    
    public func addPersonToCoffecule(_ name: String, to people: [Person]) -> [Person] {
        var newPeople = [Person]()
        for buyer in people {
            var buyer = buyer
            var coffeesOwed = buyer.coffeesOwed
            coffeesOwed[name] = 0
            buyer.coffeesOwed = coffeesOwed
            newPeople.append(buyer)
        }
        return newPeople.sorted()
    }
}
