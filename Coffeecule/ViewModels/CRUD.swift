//
//  CRUD.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/13/23.
//

import Foundation
import CloudKit
import SwiftUI

extension ViewModel {
        
    /// Prepares container by creating custom zone if needed.
    func initialize() async throws {
        do {
            try await createZoneIfNeeded()
        } catch {
            state = .error(error)
        }
    }

    
    /// Creates the custom zone in use if needed.
    private func createZoneIfNeeded() async throws {
//         Avoid the operation if this has already been done.
        guard !UserDefaults.standard.bool(forKey: "isZoneCreated") else {
            return
        }

        do {
            print(try await database.modifyRecordZones(saving: [recordZone], deleting: []))
        } catch {
            print("ERROR: Failed to create custom zone: \(error.localizedDescription)")
            throw error
        }

        UserDefaults.standard.setValue(true, forKey: "isZoneCreated")
    }
    
    
    func uploadTransaction(buyerName: String, receiverName: String) async throws {
        let id = CKRecord.ID(zoneID: recordZone.zoneID)
        let transactionRecord = CKRecord(recordType: recordType, recordID: id)
        transactionRecord["buyerName"] = buyerName
        transactionRecord["receiverName"] = receiverName
        
        Task {
            do {
                try await database.save(transactionRecord)
                
            } catch {
                debugPrint("ERROR: Failed to save new Contact: \(error)")
                throw error
            }
        }
    }
    
    func fetchPrivateAndSharedContacts() async throws -> (private: [TransactionModel], shared: [TransactionModel]) {
        // This will run each of these operations in parallel.
        async let privateTransactions = fetchTransactions(scope: .private, in: [recordZone])
        async let sharedTransactions = fetchSharedTransactions()

        return (private: try await privateTransactions, shared: try await sharedTransactions)
    }
    
    // MARK: - Private

    /// Fetches contacts for a given set of zones in a given database scope.
    /// - Parameters:
    ///   - scope: Database scope to fetch from.
    ///   - zones: Record zones to fetch contacts from.
    /// - Returns: Combined set of contacts across all given zones.
    
    #warning("make private")
    func fetchTransactions(
        scope: CKDatabase.Scope,
        in zones: [CKRecordZone]
    ) async throws -> [TransactionModel] {
        let database = container.database(with: scope)
        var allTransactions: [TransactionModel] = []

        // Inner function retrieving and converting all Contact records for a single zone.
        @Sendable func transactionsInZone(_ zone: CKRecordZone) async throws -> [TransactionModel] {
            var allTransactions: [TransactionModel] = []
            let coffeeculeMembers = await self.coffeeculeMembers

            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil
            print(coffeeculeMembers)

            while awaitingChanges {
                let zoneChanges = try await database.recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
                let transactions = zoneChanges.modificationResultsByID.values
                for completionHandler in transactions {
                    switch completionHandler {
                    case .success(let transaction):
                        guard let transaction = TransactionModel(record: transaction.record) else { continue }
                        if coffeeculeMembers.contains(transaction.buyerName) && coffeeculeMembers.contains(transaction.receiverName) {
                            allTransactions.append(transaction)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
                awaitingChanges = zoneChanges.moreComing
                nextChangeToken = zoneChanges.changeToken
            }
            return allTransactions
        }

        // Using this task group, fetch each zone's contacts in parallel.
        try await withThrowingTaskGroup(of: [TransactionModel].self) { group in
            for zone in zones {
                group.addTask {
                    try await transactionsInZone(zone)
                }
            }

            // As each result comes back, append it to a combined array to finally return.
            for try await transactionsResult in group {
                allTransactions.append(contentsOf: transactionsResult)
            }
        }
        return allTransactions
    }
    
    /// Fetches all shared Contacts from all available record zones.
    private func fetchSharedTransactions() async throws -> [TransactionModel] {
        let sharedZones = try await container.sharedCloudDatabase.allRecordZones()
        guard !sharedZones.isEmpty else {
            return []
        }

        return try await fetchTransactions(scope: .shared, in: sharedZones)
    }
    
}
