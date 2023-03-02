////
////  CloudReadWrite.swift
////  CoffeeculeTest
////
////  Created by Cory Tripathy on 2/3/23.
////
//
//import Foundation
//import CloudKit
//import SwiftUI
//
//struct CloudReadWriter: ReadWritable {
//    
//    enum CloudError: Error {
//        case cloudPermission
//    }
//    
//    func readTransactions(existingPeople: [Person]? = nil) async -> [Person] {
//        do {
//            let transactions: [CloudTransaction] = try await fetchFromPrivateContainer()
//            let people = transactionsToPeople(for: transactions, existingPeople: existingPeople)
//            return people
//        } catch {
//            print("unknown error reading from iCloud container")
//            return [Person]()
//        }
//    }
//    
//    func writeTransactionsFromStrings(buyerName: String, receiverName: String) async {
//        let id = CKRecord.ID(zoneID: Repository.shared.recordZone.zoneID)
//        let transactionRecord = CKRecord(recordType: Repository.shared.recordType, recordID: id)
//        transactionRecord["buyerName"] = buyerName
//        transactionRecord["receiverName"] = receiverName
//        
//        do {
//            try await Repository.shared.database.save(transactionRecord)
//            
//        } catch {
//            debugPrint("ERROR: Failed to save new Transaction: \(error)")
//        }
//    }
//    
//    func writeTransactions(from transactions: [CachedTransaction]) async -> [CachedTransaction]? {
//        let id = CKRecord.ID(zoneID: Repository.shared.recordZone.zoneID)
//        
//        var failedTransactions = [CachedTransaction]()
//        
//        for transaction in transactions {
//            let transactionRecord = CKRecord(recordType: Repository.shared.recordType, recordID: id)
//            transactionRecord["buyerName"] = transaction.buyerName
//            transactionRecord["receiverName"] = transaction.receiverName
//            
//            do {
//                try await Repository.shared.database.save(transactionRecord)
//                
//            } catch {
//                debugPrint("ERROR: Failed to save new Transaction: \(error)")
//                failedTransactions.append(transaction)
//            }
//            
//        }
//        if failedTransactions.count > 0 {
//            return failedTransactions
//        } else {
//            return nil
//        }
//    }
//    static let shared = Self()
//
//}
//
//
//
//
//// MARK: - CRUD functions used within the Cloud Readwriter
//extension CloudReadWriter {
//    func fetchFromPrivateContainer() async throws -> [CloudTransaction] {
//        let database = CKContainer(identifier: "iCloud.com.CoryTripathy.Coffeecule").database(with: .private)
//        var allTransactions = [CloudTransaction]()
//        
//        // Inner function retrieving and converting all Transaction records for a single zone.
//        @Sendable func transactionsInZone(_ zone: CKRecordZone) async throws -> [CloudTransaction] {
//            var allTransactions: [CloudTransaction] = []
//            
//            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
//            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
//            var awaitingChanges = true
//            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
//            var nextChangeToken: CKServerChangeToken? = nil
//            
//            while awaitingChanges {
//                guard let zoneChanges = try? await database.recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken) else {
//                    debugPrint("Make sure the user has given you cloud permissions!")
//                    throw CloudError.cloudPermission
////                    return [CloudTransaction]()
//                }
//                let transactions = zoneChanges.modificationResultsByID.values
//                for completionHandler in transactions {
//                    switch completionHandler {
//                    case .success(let transaction):
//                        if let transaction = CloudTransaction(record: transaction.record) {
//                            allTransactions.append(transaction)
//                        }
//                    case .failure(let error):
//                        print(error)
//                    }
//                }
//                awaitingChanges = zoneChanges.moreComing
//                nextChangeToken = zoneChanges.changeToken
//            }
//            return allTransactions
//        }
//        
//        // Using this task group, fetch each zone's contacts in parallel.
//        try await withThrowingTaskGroup(of: [CloudTransaction].self) { group in
//            for zone in [Repository.shared.recordZone] {
//                group.addTask {
//                    try await transactionsInZone(zone)
//                }
//            }
//            
//            // As each result comes back, append it to a combined array to finally return.
//            for try await transactionsResult in group {
//                allTransactions.append(contentsOf: transactionsResult)
//            }
//        }
//        return allTransactions
//    }
//}
//
//// MARK: - Check Cloud Status
//extension CloudReadWriter {
//    func getiCloudStatus() async  -> String {
//        guard let accountStatus = try? await CKContainer.default().accountStatus() else {
//            return "couldn't get account status for unknown reason"
//        }
//        switch accountStatus {
//        case .couldNotDetermine:
//            return "countNotDetermine"
//        case .available:
//            return "available"
//        case .restricted:
//            return "restricted"
//        case .noAccount:
//            return "noAccount"
//        case .temporarilyUnavailable:
//            return "temporarilyUnavailable"
//        @unknown default:
//            return "default"
//        }
//    }
//}
