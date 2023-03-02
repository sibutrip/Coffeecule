//
//  ReadWrite.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/28/23.
//

import Foundation
import CloudKit

struct ReadWrite: ReadWritable {
    
    func readPeopleFromDisk() -> [Person] {
        do {
            let encodedPeople = try Data(contentsOf: Repository.shared.peopleUrl)
            let decodedpeople = try JSONDecoder().decode([Person].self, from: encodedPeople)
            return decodedpeople
        } catch {
            print("error reading cachedTransactions.json data")
            return [Person]()
        }
    }
    
    func readTransactionsFromCloud() async -> [Transaction] {
        guard let records = try? await fetchFromPrivateContainer(from: .Transactions) else {
            print("no transactions found in cloud")
            return []
        }
        
        var transactions = [Transaction]()
        for record in records {
            if let transaction = Transaction(record: record) {
                transactions.append(transaction)
            }
        }
        return transactions
    }
    
    func readPeopleFromCloud() async -> [Person] {
        guard let records = try? await fetchFromPrivateContainer(from: .People) else {
            print("no people found in cloud")
            return []
        }
        if records.count > 1 {
            print("found \(records.count) number of people jsons lol")
        } else if records.count == 0 {
            print("no people stored in cloud. normal on first time launch")
            return []
        }
        guard let nsEncodedPeople = records[0]["people"] as? NSData else {
            print("cannot get value NSData from record[people]")
            return []
        }
        do {
            let encodedPeople = Data(referencing: nsEncodedPeople)
            let decodedpeople = try JSONDecoder().decode([Person].self, from: encodedPeople)
            return decodedpeople
        } catch {
            print("error reading cachedTransactions.json data")
            return []
        }
    }
        
    func writePeopleToDisk(_ people: [Person]) {
        do {
            try JSONEncoder()
                .encode(people)
                .write(to: Repository.shared.peopleUrl)
            
        } catch {
            print("couldnt write people to disk")
        }
    }
    
    func writeTransactionsToCloud(_ transactions: [Transaction]) async {
        for transaction in transactions {
            let id = CKRecord.ID(zoneID: RecordZones.Transactions().zoneID)
            let transactionRecord = CKRecord(recordType: Repository.shared.recordType, recordID: id)
            transactionRecord["buyerName"] = transaction.buyerName
            transactionRecord["receiverName"] = transaction.receiverName
            
            do {
                try await Repository.shared.database.save(transactionRecord)
                
            } catch {
                debugPrint("ERROR: Failed to save new Transaction: \(error)")
            }
        }
    }
    
    func writePeopleToCloud(_ people: [Person]) async {
        do {
            let data = try JSONEncoder().encode(people)
            let recordID = CKRecord.ID(recordName: "people", zoneID: RecordZones.People().zoneID)
            let transaction = CKRecord(recordType: Repository.shared.recordType, recordID: recordID)
            transaction["people"] = NSData(data: data)
            let (_,_) = try! await Repository.shared.database.modifyRecords(saving: [], deleting: [recordID])
            let (_,_) = try! await Repository.shared.database.modifyRecords(saving: [transaction], deleting: [])
//            let reSave = try! await Repository.shared.database.save(transaction)

        } catch {
            print("could not write people to cloud")
        }
    }
    
    static var shared = ReadWrite()
    
}
// MARK: - CRUD functions used within the Cloud Readwriter
extension ReadWrite {
    
    enum CloudError: Error {
        case cloudPermission
    }
    
    func fetchFromPrivateContainer(from zone: RecordZones) async throws -> [CKRecord] {
        var records = [CKRecord]()
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Repository.shared.recordType, predicate: predicate)
        let (matchResults, _) = try await Repository.shared.database.records(matching: query, inZoneWith: zone().zoneID, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
        for (_, result) in matchResults {
            switch result {
            case .success(let record):
                records.append(record)
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
        return records
    }
    
    
    //    func fetchFromPrivateContainer() async throws -> CloudData {
    //        var cloudData = CloudData()
    //
    //        // Inner function retrieving and converting all Transaction records for a single zone.
    //        @Sendable func recordsInZone(_ zone: RecordZones) async throws -> CloudData {
    //            var cloudData = CloudData()
    //            var allTransactions: [Transaction] = []
    //
    //            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
    //            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
    //            var awaitingChanges = true
    //            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
    //            var nextChangeToken: CKServerChangeToken? = nil
    //
    //            while awaitingChanges {
    //                guard let zoneChanges = try? await Repository.shared.database.recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken) else {
    //                    debugPrint("Make sure the user has given you cloud permissions!")
    //                    throw CloudError.cloudPermission
    //                }
    //                let transactions = zoneChanges.modificationResultsByID.values
    //                for completionHandler in transactions {
    //                    switch completionHandler {
    //
    //                        /// separate Data -> [Person] and [Transaction]
    //                    case .success(let result):
    //                        if let transaction = Transaction(record: result.record) {
    //                            allTransactions.append(transaction)
    //                        } else {
    //                            if let data = result.record["people"] as? Data {
    //                                guard let people = try? JSONDecoder().decode([Person].self, from: data) else {
    //                                    print("couldnt decode data to people from cloud")
    //                                    return CloudData()
    //                                }
    //                                cloudData.people = people
    //                            }
    //                        }
    //
    //                    case .failure(let error):
    //                        print(error)
    //                    }
    //                }
    //                awaitingChanges = zoneChanges.moreComing
    //                nextChangeToken = zoneChanges.changeToken
    //            }
    //            cloudData.transactions = allTransactions
    //
    //            return cloudData
    //        }
    //
    //        // Using this task group, fetch each zone's contacts in parallel.
    //        try await withThrowingTaskGroup(of: CloudData.self) { group in
    //            group.addTask {
    //                try await recordsInZone(Repository.shared.recordZone)
    //            }
    //
    //            // As each result comes back, append it to a combined array to finally return.
    //            for try await fetchedData in group {
    //                if fetchedData.people.count > 0 {
    //                    cloudData.people = fetchedData.people
    //                }
    //                if fetchedData.transactions.count > 0 {
    //                    cloudData.transactions.append(contentsOf: fetchedData.transactions)
    //                }
    //            }
    //        }
    //        return cloudData
    //    }
}

// MARK: - Check Cloud Status
extension ReadWrite {
    func getiCloudStatus() async  -> String {
        guard let accountStatus = try? await CKContainer.default().accountStatus() else {
            return "couldn't get account status for unknown reason"
        }
        switch accountStatus {
        case .couldNotDetermine:
            return "countNotDetermine"
        case .available:
            return "available"
        case .restricted:
            return "restricted"
        case .noAccount:
            return "noAccount"
        case .temporarilyUnavailable:
            return "temporarilyUnavailable"
        @unknown default:
            return "default"
        }
    }
}
