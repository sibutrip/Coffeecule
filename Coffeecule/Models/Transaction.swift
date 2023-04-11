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
        guard let buyerName = record["buyerName"] as? String,
              let receiverName = record["receiverName"] as? String else {
            return nil
        }

        self.id = record.recordID.recordName
        self.buyerName = buyerName.capitalized
        self.receiverName = receiverName.capitalized
        self.associatedRecord = record
    }
    
//    static func transactionsToPeople(_ transaction: [Transaction]) -> [Person]
    
    static let transactionRecordName = "transactionRecord"
    
    static func createTransaction(buyer: Person, receiver: Person) -> Transaction {
        let id = CKRecord.ID(zoneID: Repository.shared.coffeeculeRecordZone.zoneID)
        let transactionRecord = CKRecord(recordType: transactionRecordName, recordID: id)
        transactionRecord["buyerName"] = buyer.name
        transactionRecord["receiverName"] = receiver.name
        return Transaction(record: transactionRecord)!
    }
}
