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
    var creationDate: Date?
    var roundedDate: Date?
    
    init?(record: CKRecord) {
        guard let buyerName = record["buyer"] as? String,
              let receiverName = record["receiver"] as? String else {
            return nil
        }
        
        self.id = record.recordID.recordName
        self.buyerName = buyerName
        self.receiverName = receiverName
        self.associatedRecord = record
        let creationDate = record.creationDate ?? Date.now
        self.creationDate = creationDate
        self.roundedDate = creationDate.roundedToNearestDay
    }
    
    static let transactionRecordName = "transaction"
    
    init(buyer: String, receiver: String, in repository: Repository) async {
        let transactionRecord = CKRecord(recordType: Self.transactionRecordName, recordID: CKRecord.ID(recordName: UUID().uuidString, zoneID: await repository.currentZone.zoneID))
        transactionRecord["buyer"] = buyer
        transactionRecord["receiver"] = receiver
        
        self.id = transactionRecord.recordID.recordName
        self.buyerName = buyer
        self.receiverName = receiver
        self.associatedRecord = transactionRecord
        let creationDate = transactionRecord.creationDate ?? Date.now
        self.creationDate = creationDate
        self.roundedDate = creationDate.roundedToNearestDay
    }
}
