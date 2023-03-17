//
//  CloudSharingManager.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 3/3/23.
//

import Foundation
import CloudKit

struct CloudShare {
    func fetchShareRecord() async  -> (CKRecord, CKShare) {
        if let share = Repository.shared.ckShare, let rootRecord = Repository.shared.rootRecord {
            return (rootRecord, share)
        }
        
        let id = CKRecord.ID(zoneID: RecordZones.Transactions().zoneID)
        let rootRecord = CKRecord(recordType: "CoffeeculeRootTest", recordID: id)

    
        
        let share = CKShare(rootRecord: rootRecord)
        Repository.shared.ckShare = share
        Repository.shared.rootRecord = rootRecord
        
        
//        share[CKShare.SystemFieldKey.title] = "Coffeecule" as CKRecordValue?
//        share[CKShare.SystemFieldKey.shareType] = "Some type" as CKRecordValue?
        do {
            let (saveResults,_) = try await Repository.shared.database.modifyRecords(saving: [share,rootRecord], deleting: [])
        } catch {
            print("could not upload share to database")
        }
        
        return (rootRecord, share)
    }
    
    func createRecord(buyer: Person, receiver: Person) -> CKRecord {
        let id = CKRecord.ID(zoneID: RecordZones.Transactions().zoneID)
        let transactionRecord = CKRecord(recordType: Repository.shared.recordType, recordID: id)
        transactionRecord["buyerName"] = buyer.name
        transactionRecord["receiverName"] = receiver.name
        
        let reference = CKRecord.Reference(record: Repository.shared.ckShare!, action: .deleteSelf)
        transactionRecord["RootTest"] = reference
        return transactionRecord
    }
    
    func uploadRecordToCloud(_ record:CKRecord) async {
        do {
            try await Repository.shared.database.save(record)
        } catch {
            debugPrint("ERROR: Failed to save new Transaction: \(error)")
        }
    }
    
    func shareRecord() { }
    
    /// use a token to pull all new transactions
    func refreshPeople() { }
    static let shared = CloudShare()
}
