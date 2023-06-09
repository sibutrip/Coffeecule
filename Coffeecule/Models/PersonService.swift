//
//  PersonService.swift
//  SharedContainer
//
//  Created by Cory Tripathy on 3/29/23.
//

import Foundation
import SwiftUI
import CloudKit

class PersonService {
    
    // RECORD INFO
    private let rootRecordName = "rootRecord"
    private let participantRecordName = "participantRecord"
    private let repository = Repository.shared
    
    enum PeopleSource {
        case scratch, existing
    }
    
    enum PersonRecordsError: Error {
        case nameIsEmpty, recordAlreadyExists
    }
    
    // INITIALIZER
    init() { }
    
    // MARK: - PRIVATE METHODS
    
    // RECORDS METHODS
    public func fetchOrCreateShare() async -> Bool {
        if repository.rootShare != nil { return true }
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "cloudkit.share", predicate: predicate)
        
        guard let (results, _) = try? await repository.database.records(matching: query, inZoneWith: repository.currentZone.zoneID,desiredKeys: nil, resultsLimit: 10) else {
            return await createRootShare()
        }
        for (_, result) in results {
            switch result {
            case .success(let record):
                repository.rootShare = record as! CKShare?
                return true
            case .failure(let error):
                print(error)
                return false
            }
        }
        if results.count == 0 {
            return await createRootShare()
        }
        return false
    }
    
    public func fetchShare() async throws {
        enum FetchShareError: Error {
            case invalidShare,noShareFound
        }
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "cloudkit.share", predicate: predicate)
        let (results, _) = try await repository.database.records(matching: query, inZoneWith: repository.currentZone.zoneID,desiredKeys: nil, resultsLimit: 10)
        for (_, result) in results {
            switch result {
            case .success(let record):
                repository.rootShare = record as? CKShare
                return
            case .failure(_):
                throw FetchShareError.invalidShare
            }
        }
        throw FetchShareError.noShareFound
    }
    
    public func createRootShare() async -> Bool {
        let share = CKShare(recordZoneID: repository.currentZone.zoneID)
        share.publicPermission = .readWrite
        share[CKShare.SystemFieldKey.title] = "Coffeecule"
        let resultTest = try! await self.repository.database.modifyRecords(saving: [share], deleting: [])
        repository.rootShare = share
        return true
    }
    
//    public func createRecord(for name: String, type: ParticipantType) -> CKRecord {
//        let record = CKRecord(recordType: type.rawValue, recordID: CKRecord.ID(recordName: Repository.shared.userName!, zoneID: repository.currentZone.zoneID))
//        record["name"] = name
//        repository.rootRecord = record
//        return record
//    }
    
    public func saveRecord(_ record: CKRecord, participantType: ParticipantType) async throws {
        switch participantType {
        case .root:
            try await savePrivateRecord(record)
            repository.rootRecord = record
        case .participant:
            try await saveSharedRecord(record)
        }
    }
    private func saveSharedRecord(_ record: CKRecord) async throws {
        let _ = try await Repository.shared.container.sharedCloudDatabase.modifyRecords(saving: [record], deleting: [])
    }
    
    private func savePrivateRecord(_ record: CKRecord) async throws {
        let _ = try await self.repository.database.modifyRecords(saving: [record], deleting: [])
    }
    
    /// fetches from private container
    public func fetchPrivatePeople() async -> [CKRecord] {
        var records = [CKRecord]()
        let predicate = NSPredicate(value: true)
        
        let queries: [CKQuery] = [rootRecordName,participantRecordName].map {
            CKQuery(recordType: $0, predicate: predicate)
        }
        
        do {
            for query in queries {
                let (results, _) = try await self.repository.database.records(matching: query, inZoneWith: repository.currentZone.zoneID,desiredKeys: nil, resultsLimit: 100)
                for (_, result) in results {
                    switch result {
                    case .success(let record):
                        records.append(record)
                        if query.recordType == rootRecordName {
                            repository.rootRecord = record
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
    public func fetchRecords() async -> ([Person], [Transaction], Bool) {
        var people: [Person] = []
        var transactions: [Transaction] = []
        var hasShare: Bool = false
        
        @Sendable func recordsInZone(_ zone: CKRecordZone, scope: CKDatabase.Scope) async throws -> ([Person], [Transaction], Bool) {
            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil
            var people: [Person] = []
            var transactions: [Transaction] = []
            var hasShare: Bool = false
            
            while awaitingChanges {
                let zoneChanges = try await Repository.shared.container.database(with: scope).recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
                let receivedRecords = zoneChanges.modificationResultsByID.values
                    .compactMap { try? $0.get().record }
                awaitingChanges = zoneChanges.moreComing
                nextChangeToken = zoneChanges.changeToken
                for record in receivedRecords {
                    if record.recordType == rootRecordName {
                        let name = record["name"] as! String
                        people.append(Person(name: name, associatedRecord: record))
                        print("found root record")
                        repository.rootRecord = record
                    } else if record.recordType == participantRecordName {
                        let name = record["name"] as! String
                        people.append(Person(name: name, associatedRecord: record))
                        print("found participant record")
                    } else if record.recordType == "transaction" {
                        transactions.append(Transaction(record: record)!)
                    } else if record.recordType == "cloudkit.share" {
                        repository.rootShare = record as? CKShare
                        hasShare = true
                    }
                }
            }
            return (people, transactions, hasShare)
        }
        do {
            try await Repository.shared.fetchSharedContainer()
            let zones = Repository.shared.allZones
            
            // Using this task group, fetch each zone's contacts in parallel.
            try await withThrowingTaskGroup(of: ([Person], [Transaction], Bool).self) { group in
                for zone in zones {
                    group.addTask {
                        
                        // if shared records are found return them and exit the function without fetching private records.
                        if let results = try? await recordsInZone(zone, scope: .shared) {
                            print("found shared zone records")
                            return results
                        }
                        if let results = try? await recordsInZone(zone, scope: .private) {
                            print("found private zone records")
                            return results
                        }
                        print("found no zone records")
                        return ([], [], false)
                        
                    }
                    
                    // As each result comes back, append it to a combined array to finally return.
                    for try await (returnedPeople, returnedTransactions, didReturnShare) in group {
                        people.append(contentsOf: returnedPeople)
                        transactions.append(contentsOf: returnedTransactions)
                        if didReturnShare {
                            hasShare = true
                        }
                    }
                }
            }
        } catch { print(error.localizedDescription) }
        self.repository.transactions = transactions
        return (people, transactions, hasShare)
    }
    
    //    public func addPersonToCoffecule(_ name: String, to people: [Person]) -> [Person] {
    //        var newPeople = [Person]()
    //        for buyer in people {
    //            var buyer = buyer
    //            var coffeesOwed = buyer.coffeesOwed
    //            coffeesOwed[name] = 0
    //            buyer.coffeesOwed = coffeesOwed
    //            newPeople.append(buyer)
    //        }
    //        return newPeople.sorted()
    //    }
    
    //    func createPeopleFromScratch(from names: [String]) -> [Person] {
    //        //        let names = records.map {
    //        //            $0.recordID.recordName
    //        //        }
    //        var people = names
    //            .map { Person(name: $0) }
    //        for name in names {
    //            for index in 0..<people.count {
    //                if name != people[index].name {
    //                    people[index].coffeesOwed[name] = 0
    //                }
    //            }
    //        }
    //        return people
    //    }
    
    //    func createPeopleFromExisting(with transactions: [Transaction], and people: [Person]) -> [Person] {
    //
    //        var peopleToAdd = people
    //
    //        for transaction in transactions {
    //            let buyer = transaction.buyerName
    //            let receiver = transaction.receiverName
    //            peopleToAdd = incrementDebt(buyer: buyer, receiver: receiver, in: peopleToAdd)
    //            peopleToAdd = decrementDebt(buyer: buyer, receiver: receiver, in: peopleToAdd)
    //        }
    //        //        _ = people.map {
    //        //            print($0.coffeesOwed)
    //        //        }
    //        return peopleToAdd
    //    }
    
    //    private func incrementDebt(buyer: String, receiver: String, in people: [Person]) -> [Person] {
    //        var people = people
    //        guard let buyerIndex = people.firstIndex(where: {
    //            $0.name == buyer
    //        }) else {
    //            debugPrint("transaction buyer: \(buyer) is not in the people array")
    //            return [Person]()
    //        }
    //
    //        var newBuyerDebt = people[buyerIndex].coffeesOwed[receiver] ?? 0
    //        newBuyerDebt += 1
    //        people[buyerIndex].coffeesOwed[receiver] = newBuyerDebt
    //        return people
    //    }
    
    //    private func decrementDebt(buyer: String, receiver: String, in people: [Person]) -> [Person] {
    //        var people = people
    //        guard let receiverIndex = people.firstIndex(where: {
    //            $0.name == receiver
    //        }) else {
    //            debugPrint("transaction receiver: \(receiver) is not in the people array")
    //            return [Person]()
    //        }
    //
    //        var newReceiverDebt = people[receiverIndex].coffeesOwed[buyer] ?? 0
    //        newReceiverDebt -= 1
    //        people[receiverIndex].coffeesOwed[buyer] = newReceiverDebt
    //        return people
    //    }
    
    public func deleteAllTransactions() async throws {
        //        let zoneIDs = Repository.shared.allZones.map { $0.zoneID }
        guard let transactions = repository.transactions else { return }
        let recordIDs = transactions.map { $0.associatedRecord.recordID }
        let _ = try await Repository.shared.database.modifyRecords(saving: [], deleting: recordIDs)
    }
    
    public func deleteAllUsers(_ relationships: [Relationships]) async throws {
        let peopleRecordIDs = relationships.map { $0.person.associatedRecord.recordID }
        let _ = try await Repository.shared.database.modifyRecords(saving: [], deleting: peopleRecordIDs)
    }
    
    public func deleteShare() async throws {
        if let share = repository.rootShare {
            let _ = try await Repository.shared.database.modifyRecords(saving: [], deleting: [share.recordID])
        }
    }
    
}
