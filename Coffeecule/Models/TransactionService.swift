//
//  TransactionService.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

class TransactionService {
    private let transactionRecordName = "transactionRecord"
    private let repository = Repository.shared
    
    public func saveTransaction(_ transaction: Transaction) async throws {
        if let zone = self.repository.sharedCoffeeculeZone {
            let record = CKRecord(recordType: transactionRecordName, recordID: CKRecord.ID(recordName: transaction.id, zoneID: zone.zoneID))
            let _ = try await repository.container.sharedCloudDatabase.modifyRecords(saving: [record], deleting: [])
        }
    }
    
}
