//
//  TransactionService.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

class TransactionService {
//    private let repository = Repository.shared
    
    public func saveTransactions(_ transactions: [Transaction], in database: CKDatabase) async throws {
        let records: [CKRecord] = transactions.map { $0.associatedRecord }
        let (result,_) = try await database.modifyRecords(saving: records, deleting: [])
        result.forEach {print($0.value)}
//        let result = try await Repository.shared.container.privateCloudDatabase.modifyRecords(saving: records, deleting: [])
    }
}
