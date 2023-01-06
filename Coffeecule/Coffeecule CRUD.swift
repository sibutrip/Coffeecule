//
//  Coffeecule CRUD.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/8/23.
//

import CloudKit
import SwiftUI

struct TransactionModel: Hashable {
    var buyerName: String
    var receiverName: String
    var record: CKRecord
}

extension ViewModel {
    
    func addItem(buyerName: String, receiverName: String) {
        let newTransaction = CKRecord(recordType: "Transactions")
        newTransaction["buyerName"] = buyerName
        newTransaction["receiverName"] = receiverName
        saveItem(record: newTransaction)
    }
    
    private func saveItem(record: CKRecord) {
        CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, returnedError in
            print("Ahh")
        }
        DispatchQueue.main.async { }
    }
    func fetchItems() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Transactions", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInteractive
        
        var returnedTransactions: [TransactionModel] = []
        
        queryOperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let buyerName = record["buyerName"] as? String else { return }
                guard let receiverName = record["receiverName"] as? String else { return }
                returnedTransactions.append(TransactionModel(buyerName: buyerName, receiverName: receiverName, record: record))
            case .failure(let error):
                print("Error recordMatchedBlock: \(error)")
            }
        }
        
        queryOperation.queryResultBlock = { returnedResult in
            DispatchQueue.main.async {
                self.transactions = returnedTransactions
            }
        }
        addOperation(operation: queryOperation)
    }
    
    private func addOperation(operation: CKQueryOperation) {
        operation.qualityOfService = .userInteractive
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    private func updateItem(recipient: String) {
        let record = CKRecord(recordType: "Transaction")
        for person in presentPeople {
                record["buyerName"] = currentBuyer
                record["receiverName"] = person
                saveItem(record: record)
        }
    }
}
