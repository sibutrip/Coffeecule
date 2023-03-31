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
        self.buyerName = buyerName.lowercased()
        self.receiverName = receiverName.lowercased()
        self.associatedRecord = record
    }
}
