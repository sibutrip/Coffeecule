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
    
    enum PeopleSource {
        case scratch, existing
    }
    
    enum PersonRecordsError: Error {
        case nameIsEmpty, recordAlreadyExists
    }
    
    // INITIALIZER
    init() {
        //        Task {
        //            try? repository.fetchSharedContainer()
        //        }
    }
    
    // MARK: - PRIVATE METHODS
    
    // RECORDS METHODS
    public func fetchOrCreateShare() async {
        if self.rootShare != nil { return }
        var share: CKShare? = nil
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "cloudkit.share", predicate: predicate)
        
        guard let (results, _) = try? await repository.database.records(matching: query, inZoneWith: repository.coffeeculeRecordZone.zoneID,desiredKeys: nil, resultsLimit: 10) else {
            self.rootShare = await createRootShare()
            return
        }
        for (_, result) in results {
            switch result {
            case .success(let record):
                share = record as! CKShare?
            case .failure(let error):
                print(error)
            }
        }
        if results.count == 0 {
            self.rootShare = await createRootShare()
            return
        }
        self.rootShare = share
    }
    
    public func fetchShare() async throws {
        enum FetchShareError: Error {
            case invalidShare,noShareFound
        }
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "cloudkit.share", predicate: predicate)
        let (results, _) = try await repository.database.records(matching: query, inZoneWith: repository.coffeeculeRecordZone.zoneID,desiredKeys: nil, resultsLimit: 10)
        for (_, result) in results {
            switch result {
            case .success(let record):
                self.rootShare = record as? CKShare
                return
            case .failure(_):
                throw FetchShareError.invalidShare
            }
        }
        throw FetchShareError.noShareFound
    }
    
    private func createRootShare() async -> CKShare {
        let share = CKShare(recordZoneID: repository.coffeeculeRecordZone.zoneID)
        share.publicPermission = .readWrite
        share[CKShare.SystemFieldKey.title] = "Coffeecule"
        let resultTest = try! await self.repository.database.modifyRecords(saving: [share], deleting: [])
        print(resultTest.saveResults.debugDescription)
        return share
    }
    
    public func createRootRecord(for name: String, in people: [Person]) throws -> CKRecord {
        if name.isEmpty { throw PersonRecordsError.nameIsEmpty }
        if people.contains(where: { person in
            person.name == name
        }) {
            throw PersonRecordsError.recordAlreadyExists
        }
        let record = CKRecord(recordType: rootRecordName, recordID: CKRecord.ID(recordName: name, zoneID: repository.coffeeculeRecordZone.zoneID))
        self.rootRecord = record
        return record
    }
    
    public func createParticipantRecord(for name: String, in people: [Person]) async throws -> CKRecord {
        if name.isEmpty { throw PersonRecordsError.nameIsEmpty }
        if people.contains(where: { person in
            person.name == name
        }) {
            throw PersonRecordsError.recordAlreadyExists
        }
//        let zone = try await repository.container.sharedCloudDatabase.allRecordZones()[0]
        let record = CKRecord(recordType: participantRecordName, recordID: CKRecord.ID(recordName: name, zoneID: repository.coffeeculeRecordZone.zoneID))
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
            print(result.saveResults.debugDescription)
        } catch {
            debugPrint(error)
        }
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
    public func fetchRecords() async -> ([String], [Transaction], Bool) {
        var people: [String] = []
        var transactions: [Transaction] = []
        var hasShare: Bool = false
        
        @Sendable func recordsInZone(_ zone: CKRecordZone, scope: CKDatabase.Scope) async throws -> ([String], [Transaction], Bool) {
            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil
            var people: [String] = []
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
                        people.append(record.recordID.recordName)
                        print("found root record")
                        self.rootRecord = record
                    } else if record.recordType == participantRecordName {
                        print("found partic record")

                        people.append(record.recordID.recordName)
                    } else if record.recordType == "transaction" {
                        transactions.append(Transaction(record: record)!)
                    } else if record.recordType == "cloudkit.share" {
                        self.rootShare = record as? CKShare
                        hasShare = true
                    }
                }
            }
            return (people, transactions, hasShare)
        }
        
        do {
//            var zones = [CKRecordZone]()
//            if let sharedZones = try? await repository.container.sharedCloudDatabase.allRecordZones() {
//                zones.append(contentsOf: sharedZones)
//            }
//            let privateZone = repository.coffeeculeRecordZone
//            zones.append(privateZone)
            try await repository.fetchSharedContainer()
            var zones = [repository.coffeeculeRecordZone]
            
            // Using this task group, fetch each zone's contacts in parallel.
            try await withThrowingTaskGroup(of: ([String], [Transaction], Bool).self) { group in
                for zone in zones {
                    group.addTask {
                        if let results = try? await recordsInZone(zone, scope: .shared) {
                            return results
                        }
                        if let results = try? await recordsInZone(zone, scope: .private) {
                            return results
                        }
                        return ([], [], false)

                    }
                    
                    // As each result comes back, append it to a combined array to finally return.
                    for try await (returnedPeople, returnedTransactions, didReturnShare) in group {
                        people.append(contentsOf: returnedPeople)
                        transactions.append(contentsOf: returnedTransactions)
                        hasShare = didReturnShare
                    }
                }
            }
            return (people, transactions, hasShare)
        } catch {
            debugPrint(error.localizedDescription+"Aaaa")
            return([], [], false)
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
    
    func createPeopleFromScratch(from names: [String]) -> [Person] {
        //        let names = records.map {
        //            $0.recordID.recordName
        //        }
        var people = names
            .map { Person(name: $0) }
        for name in names {
            for index in 0..<people.count {
                if name != people[index].name {
                    people[index].coffeesOwed[name] = 0
                }
            }
        }
        return people
    }
    
    func createPeopleFromExisting(with transactions: [Transaction], and people: [Person]) -> [Person] {
        
        var peopleToAdd = people
        
        for transaction in transactions {
            let buyer = transaction.buyerName
            let receiver = transaction.receiverName
            peopleToAdd = incrementDebt(buyer: buyer, receiver: receiver, in: peopleToAdd)
            peopleToAdd = decrementDebt(buyer: buyer, receiver: receiver, in: peopleToAdd)
        }
        //        _ = people.map {
        //            print($0.coffeesOwed)
        //        }
        return peopleToAdd
    }
    
    private func incrementDebt(buyer: String, receiver: String, in people: [Person]) -> [Person] {
        var people = people
        guard let buyerIndex = people.firstIndex(where: {
            $0.name == buyer
        }) else {
            debugPrint("transaction buyer: \(buyer) is not in the people array")
            return [Person]()
        }
        
        var newBuyerDebt = people[buyerIndex].coffeesOwed[receiver] ?? 0
        newBuyerDebt += 1
        people[buyerIndex].coffeesOwed[receiver] = newBuyerDebt
        return people
    }
    
    private func decrementDebt(buyer: String, receiver: String, in people: [Person]) -> [Person] {
        var people = people
        guard let receiverIndex = people.firstIndex(where: {
            $0.name == receiver
        }) else {
            debugPrint("transaction receiver: \(receiver) is not in the people array")
            return [Person]()
        }
        
        var newReceiverDebt = people[receiverIndex].coffeesOwed[buyer] ?? 0
        newReceiverDebt -= 1
        people[receiverIndex].coffeesOwed[buyer] = newReceiverDebt
        return people
    }
}
