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
    
    let repository: Repository
    
    // RECORD INFO
    private let rootRecordName = "rootRecord"
    private let participantRecordName = "participantRecord"
    
    enum PeopleSource {
        case scratch, existing
    }
    
    enum PersonRecordsError: Error {
        case nameIsEmpty, recordAlreadyExists
    }
    
    // INITIALIZER
    init(with repo: Repository) {
        self.repository = repo
    }
    
    // MARK: - PRIVATE METHODS
    
    // RECORDS METHODS
    public func fetchOrCreateShare() async throws -> Bool {
        if await repository.rootShare != nil { return true }
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "cloudkit.share", predicate: predicate)
        
        guard let (results, _) = try? await Repository.database.records(matching: query, inZoneWith: repository.currentZone.zoneID,desiredKeys: nil, resultsLimit: 10) else {
            return try await createRootShare()
        }
        for (_, result) in results {
            switch result {
            case .success(let record):
                let share = record as! CKShare
                await repository.share(share)
                return true
            case .failure(let error):
                print(error)
                return false
            }
        }
        if results.count == 0 {
            return try await createRootShare()
        }
        return false
    }
    
    public func fetchShare() async throws {
        enum FetchShareError: Error {
            case invalidShare,noShareFound
        }
        
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "cloudkit.share", predicate: predicate)
        let (results, _) = try await Repository.database.records(matching: query, inZoneWith: repository.currentZone.zoneID,desiredKeys: nil, resultsLimit: 10)
        for (_, result) in results {
            switch result {
            case .success(let record):
                let share = record as! CKShare
                await repository.share(share)
                return
            case .failure(_):
                throw FetchShareError.invalidShare
            }
        }
        throw FetchShareError.noShareFound
    }
    
    public func createRootShare() async throws -> Bool {
        let share = CKShare(recordZoneID: await repository.currentZone.zoneID)
        share.publicPermission = .readWrite
        share[CKShare.SystemFieldKey.title] = "Coffeecule"
        do {
            let (result,_) = try await Repository.database.modifyRecords(saving: [share], deleting: [])
            let errors: [Error] = result.compactMap { result in
                switch result.value {
                case .success(_):
                    return nil
                case .failure(let error):
                    return error
                }
            }
            if errors.count > 0 {
                throw PersonError.couldntCreateRootShare
            }
        } catch {
            throw PersonError.couldntCreateRootShare
        }
        await repository.share(share)
        return true
    }
    
    //    public func createRecord(for name: String, type: ParticipantType) -> CKRecord {
    //        let record = CKRecord(recordType: type.rawValue, recordID: CKRecord.ID(recordName: Repository.shared.userName!, zoneID: repository.currentZone.zoneID))
    //        record["name"] = name
    //        repository.rootRecord = record
    //        return record
    //    }
    
    public func saveRecord(_ record: CKRecord, participantType: ParticipantType) async throws {
        do {
            switch participantType {
            case .root:
                try await savePrivateRecord(record)
                await repository.rootRecord(record)
            case .participant:
                try await saveSharedRecord(record)
            }
        } catch {
            throw PersonError.couldntCreateRootRecord
        }
    }
    private func saveSharedRecord(_ record: CKRecord) async throws {
        let (result,_) = try await Repository.container.sharedCloudDatabase.modifyRecords(saving: [record], deleting: [])
        result.forEach {
            switch $0.value {
            case .failure(let error):
                print(error.localizedDescription)
            default:
                _ = 1
            }
        }
    }
    
    private func savePrivateRecord(_ record: CKRecord) async throws {
        let (result,_) = try await Repository.database.modifyRecords(saving: [record], deleting: [])
        result.forEach {
            switch $0.value {
            case .failure(let error):
                print(error.localizedDescription)
            default:
                _ = 1
            }
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
                let (results, _) = try await Repository.database.records(matching: query, inZoneWith: repository.currentZone.zoneID,desiredKeys: nil, resultsLimit: 100)
                for (_, result) in results {
                    switch result {
                    case .success(let record):
                        records.append(record)
                        if query.recordType == rootRecordName {
                            await repository.rootRecord(record)
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
        
        @Sendable func recordsInZone(_ zone: CKRecordZone, scope: CKDatabase.Scope) async -> FetchTask {
            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil
            var people: [Person] = []
            var transactions: [Transaction] = []
            var hasShare: Bool = false
            
            while awaitingChanges {
                let receivedRecords: [CKRecord]
                do {
                    let zoneChanges = try await Repository.container.database(with: scope).recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
                    receivedRecords = zoneChanges.modificationResultsByID.values
                        .compactMap { try? $0.get().record }
                    awaitingChanges = zoneChanges.moreComing
                    nextChangeToken = zoneChanges.changeToken
                } catch {
                    receivedRecords = []
                    awaitingChanges = false
                }
                for record in receivedRecords {
                    if record.recordType == rootRecordName {
                        let name = record["name"] as! String
                        let existingRootRecord = await repository.rootRecord?["userID"] as? String
//                        if let existingRootRecord {
//                            if existingRootRecord != record["userID"] as String? {
//                                foundMultipleRootRecords = true
//                            }
//                        }
                        people.append(Person(name: name, associatedRecord: record))
                        print("found root record")
                        
                        await repository.rootRecord(record)
                    } else if record.recordType == participantRecordName {
                        let name = record["name"] as! String
                        people.append(Person(name: name, associatedRecord: record))
                        print("found participant record")
                    } else if record.recordType == "transaction" {
                        transactions.append(Transaction(record: record)!)
                    } else if record.recordType == "cloudkit.share" {
                        let share = record as! CKShare
                        await repository.share(share)
                        hasShare = true
                    }
                }
            }
            return FetchTask(
                people: people,
                transactions: transactions,
                foundShare: hasShare)
        }
        do {
            let zones = await repository.allZones
            print("fetching records from \(zones.count) zone(s):")
            
            // Using this task group, fetch each zone's contacts in parallel.
            try await withThrowingTaskGroup(of: FetchTask.self) { group in
                for zone in zones {
                    group.addTask {
                        do {
                            var allResults = FetchTask()
                            let sharedResults = await recordsInZone(zone, scope: .shared)
                            let privateResults = await recordsInZone(zone, scope: .private)
                            allResults.people = sharedResults.people + privateResults.people
                            allResults.transactions = sharedResults.transactions + privateResults.transactions
                            allResults.foundShare = (sharedResults.foundShare || privateResults.foundShare)
                            return allResults
                        }
                    }
                    
                    // As each result comes back, append it to a combined array to finally return.
                    for try await results in group {
                        people.append(contentsOf: results.people)
                        transactions.append(contentsOf: results.transactions)
                        if results.foundShare {
                            hasShare = true
                        }
                    }
                }
            }
        } catch { print(error.localizedDescription) }
        await repository.transactions(transactions)
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
        guard let transactions = await repository.transactions else { return }
        let recordIDs = transactions.map { $0.associatedRecord.recordID }
        let (_, deleteResults) = try await Repository.database.modifyRecords(saving: [], deleting: recordIDs)
        let errors: [String] = deleteResults.compactMap { deleteResult in
            switch deleteResult.1 {
            case .success():
                return nil
            case .failure(let failure):
                return failure.localizedDescription
            }
        }
        print(errors)
    }
    
    public func deleteAllUsers(_ relationships: [Relationship]) async throws {
        let peopleRecordIDs = relationships.map { $0.person.associatedRecord.recordID }
        let (_, deleteResults) = try await Repository.database.modifyRecords(saving: [], deleting: peopleRecordIDs)
        //        results.forEach {print($0.value)}
        let errors: [String] = deleteResults.compactMap { deleteResult in
            switch deleteResult.1 {
            case .success():
                return nil
            case .failure(let failure):
                return failure.localizedDescription
            }
        }
        print(errors)
    }
    
    public func deleteShare() async throws {
        if let share = await repository.rootShare {
            let (_, deleteResults) = try await Repository.database.modifyRecords(saving: [], deleting: [share.recordID])
            let errors: [String] = deleteResults.compactMap { deleteResult in
                switch deleteResult.1 {
                case .success():
                    return nil
                case .failure(let failure):
                    return failure.localizedDescription
                }
            }
            print(errors)
        }
        await repository.share(nil)
    }
}
