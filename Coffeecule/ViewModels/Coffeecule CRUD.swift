//
//  Coffeecule CRUD.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/8/23.
//

import CloudKit
import SwiftUI


extension ViewModel {
    
    func checkiCloudStatus() {
        CKContainer.default().accountStatus { returnedStatus, returnedError in
            CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] returnedStatus, returnedError in
                DispatchQueue.main.async {
                    guard let coffeeculeMembersData = self?.coffeeculeMembersData else { return }
                    let people = JSONUtility().decodeCoffeeculeMembers(for: coffeeculeMembersData)
                    self?.generateRelationshipWeb(for: people)
                    self?.cachedTransactions = JSONUtility().decodeCache()
                    if returnedStatus == .granted {
                        // iCLOUD IS ACTIVE
                        // upload transactions, fetch cache, populate web from cloud, save web to JSON
                        self?.uploadCachedTransactions()
                        self?.fetchItems()
                        if let web = self?.relationshipWeb {
                            JSONUtility().encodeWeb(for: web)
//                            print("web encoded")
                        } else {print("web not encoded")}
//                        print("from cloud!")
                    } else {
                        // iCLOUD IS INACTIVE
                        self?.populateRelationshipWeb(from: .Cache)
//                        print("from cache!")
                    }
                }
            }
        }
    }
    
    private func uploadCachedTransactions() {
        var transactionsToUpload = cachedTransactions
        self.cachedTransactions.removeAll()
        while transactionsToUpload.count > 0 {
            if let poppedCachedTransaction = transactionsToUpload.popLast() {
                self.addItem(buyerName: poppedCachedTransaction[0], receiverName: poppedCachedTransaction[1])
//                print("cached transaction \(poppedCachedTransaction) uploaded to cloud")
            }
        }
//        print("yooo you deleted cached transactions: \(self.cachedTransactions)")
        JSONUtility().encodeCache(for: self.cachedTransactions)
//        print("yooo you rewrote cached transactions: \(self.cachedTransactions)")
    }
    
    
    func addItem(buyerName: String, receiverName: String) {
        /// create a CK record
        let newTransaction = CKRecord(recordType: cloudContainer)
        newTransaction["buyerName"] = buyerName
        newTransaction["receiverName"] = receiverName
        saveItem(record: newTransaction)
    }
    
    
    private func saveItem(record: CKRecord) {
        /// save record to cloud
        CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, returnedError in
            if returnedError != nil {
                // add record to cache if unable to upload
                guard let cachedBuyerName = record["buyerName"] as? String else { return }
                guard let cachedReceiverName = record["receiverName"] as? String else { return }
                self.cachedTransactions.append([cachedBuyerName,cachedReceiverName])
                JSONUtility().encodeCache(for: self.cachedTransactions)
//                print("transaction couldnt upload, cached Transactions are \(self.cachedTransactions)")
            } else if returnedRecord != nil {
//                print("buyer: \(record["buyerName"]!) receiver: \(record["receiverName"]!) uploaded to cloud!")
            }
        }
        DispatchQueue.main.async { }
    }
    
    func fetchItems() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: cloudContainer, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInteractive
        
        var returnedTransactions: [TransactionModel] = []
        
        queryOperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            //            print("fetched!")
            switch returnedResult {
            case .success(let record):
                guard let buyerName = record["buyerName"] as? String else { return }
                guard let receiverName = record["receiverName"] as? String else { return }
                returnedTransactions.append(TransactionModel(buyerName: buyerName, receiverName: receiverName, record: record))
            default:
                break
            }
        }
        
        queryOperation.queryResultBlock = { returnedResult in
            DispatchQueue.main.async {
                self.transactions = returnedTransactions
                self.populateRelationshipWeb(from: .Cloud)
//                print("web after fetch is \(self.relationshipWeb)")
            }
        }
        addOperation(operation: queryOperation)
    }
    
    private func addOperation(operation: CKQueryOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    private func updateItem(recipient: String) {
        let record = CKRecord(recordType: cloudContainer)
        for person in presentPeople {
            record["buyerName"] = currentBuyer
            record["receiverName"] = person
            saveItem(record: record)
        }
    }
}
