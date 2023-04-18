//
//  TransactionModel.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/3/23.
//

import Foundation
import CloudKit

struct Transaction: Identifiable {
    let id: String
    var buyerName: String
    var receiverName: String
    var associatedRecord: CKRecord
    
    init?(record: CKRecord) {
        guard let buyerName = record["buyer"] as? String,
              let receiverName = record["receiver"] as? String else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.buyerName = buyerName.capitalized
        self.receiverName = receiverName.capitalized
        self.associatedRecord = record
    }
    
    static let transactionRecordName = "transaction"
    
    init?(buyer: String, receiver: String, in scope: CKRecordZone) {
        //        if let zone = Repository.shared.sharedCoffeeculeZone {
        let transactionRecord = CKRecord(recordType: Self.transactionRecordName, recordID: CKRecord.ID(recordName: Date().description, zoneID: scope.zoneID))
        transactionRecord["buyer"] = buyer.capitalized
        transactionRecord["receiver"] = receiver.capitalized
        
        self.id = transactionRecord.recordID.recordName
        self.buyerName = buyer.capitalized
        self.receiverName = buyer.capitalized
        self.associatedRecord = transactionRecord
        print("init success!!! u did it")
        //        } else {
        //            print("init failed")
        //            return nil
        //        }
    }
}
