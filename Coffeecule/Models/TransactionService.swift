//
//  TransactionService.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

class TransactionService {
    private let repository = Repository.shared
    
    public func saveTransactions(_ transactions: [Transaction]) async throws {
        let records: [CKRecord] = transactions.map { $0.associatedRecord }
//        let result = try await Repository.shared.container.sharedCloudDatabase.modifyRecords(saving: records, deleting: [])
        let result = try await Repository.shared.container.privateCloudDatabase.modifyRecords(saving: records, deleting: [])
        print(result.saveResults.description)
    }
}
