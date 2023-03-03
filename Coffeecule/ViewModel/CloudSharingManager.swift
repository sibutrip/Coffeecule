//
//  CloudSharingManager.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 3/3/23.
//

import Foundation
import CloudKit

struct CloudShare {
    func createShareRecord() async  -> CKShare {
        let rootRecord = CKRecord(recordType: "CoffeeculeRootTest")
        let share = CKShare(rootRecord: rootRecord)
        do {
            try await Repository.shared.database.save(share)
        } catch {
            print("could not upload share to database")
        }
        return share
    }
    
    func createRecord(buyer: Person, receiver: Person) async -> CKRecord {
        let id = CKRecord.ID(zoneID: RecordZones.Transactions().zoneID)
        let transactionRecord = CKRecord(recordType: Repository.shared.recordType, recordID: id)
        transactionRecord["buyerName"] = buyer.name
        transactionRecord["receiverName"] = receiver.name
        
        Task {
            var share: CKShare
            if let storedShare = Repository.shared.ckShare {
                share = storedShare
            } else {
                share = await createShareRecord()
            }
            
            let reference = CKRecord.Reference(record: share, action: .deleteSelf)
            transactionRecord["CoffeeculeRoot"] = reference
        }
        return transactionRecord
    }
    
    /// use a token to pull all new transactions
    func refreshPeople() { }
}
