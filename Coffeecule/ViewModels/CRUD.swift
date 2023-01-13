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
        // Avoid the operation if this has already been done.
        guard !UserDefaults.standard.bool(forKey: "isZoneCreated") else {
            return
        }

        do {
            _ = try await database.modifyRecordZones(saving: [recordZone], deleting: [])
        } catch {
            print("ERROR: Failed to create custom zone: \(error.localizedDescription)")
            throw error
        }

        UserDefaults.standard.setValue(true, forKey: "isZoneCreated")
    }
    
    
    func uploadTransaction(buyerName: String, receiverName: String) async throws {
        let id = CKRecord.ID(zoneID: recordZone.zoneID)
        let transactionRecord = CKRecord(recordType: "Transaction", recordID: id)
        transactionRecord["buyerName"] = buyerName
        transactionRecord["receiverName"] = receiverName
        
        do {
            try await database.save(transactionRecord)
        } catch {
            debugPrint("ERROR: Failed to save new Contact: \(error)")
            throw error
        }
    }
    
    
}
