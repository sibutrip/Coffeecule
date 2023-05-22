//
//  ReadWriterProtocol.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit

typealias ReadWritable = Readable & Writable

protocol Readable {
    func readPeopleFromDisk() -> [Person]
    func readTransactionsFromCloud() async -> [Transaction]
    func readPeopleFromCloud() async -> [Person]?
}

protocol Writable {
    
    func writePeopleToDisk(_ people: [Person])
    func writePeopleToCloud(_ people: [Person]) async
    func writeTransactionsToCloud(_ transactions: [Transaction]) async
}

extension Readable {
    func transactionsToPeople(_ transactions: [Transaction], people: [Person]) -> [Person] {
//        var peopleToAdd = [Person]()
     
        var names = people.map {
            $0.name.lowercased()
        }
        
        var peopleToAdd = [Person]()
        for buyer in names {
            var newPerson = Person(name: buyer)
            for receiver in names {
                if receiver != buyer {
                    newPerson.coffeesOwed[receiver] = 0
                }
            }
            peopleToAdd.append(newPerson)
        }
        
        for transaction in transactions {
            
            let buyer = transaction.buyerName.lowercased()
            let receiver = transaction.receiverName.lowercased()
            
            if !names.contains(buyer) {
                names.append(buyer)
//                peopleToAdd.append(Person(name: buyer))
            }
            if !names.contains(receiver) {
                names.append(receiver)
//                peopleToAdd.append(Person(name: receiver))
            }
                        
            guard let buyerIndex = peopleToAdd.firstIndex(where: {
                $0.name == buyer
            }) else {
                debugPrint("transaction buyer: \(buyer) is not in the people array")
                return [Person]()
            }
            
            var newBuyerDebt = peopleToAdd[buyerIndex].coffeesOwed[receiver] ?? 0
            newBuyerDebt += 1
            peopleToAdd[buyerIndex].coffeesOwed[receiver] = newBuyerDebt
            
            guard let receiverIndex = peopleToAdd.firstIndex(where: {
                $0.name == receiver
            }) else {
                debugPrint("transaction receiver: \(receiver) is not in the people array")
                return [Person]()
            }
            
            var newReceiverDebt = peopleToAdd[receiverIndex].coffeesOwed[buyer] ?? 0
            newReceiverDebt -= 1
            peopleToAdd[receiverIndex].coffeesOwed[buyer] = newReceiverDebt
        }
        return peopleToAdd
    }
}

extension Writable {
    func peopleToTransactions(currentBuyer: Person, people: [Person]) async throws -> [Transaction] {
        var transactions = [Transaction]()
        let buyer = currentBuyer
        for receiver in people {
            if receiver.isPresent {
                if receiver != currentBuyer {
                    let id = CKRecord.ID(zoneID: Repository.shared.recordZone.zoneID)
                    let transactionRecord = CKRecord(recordType: Repository.shared.recordType, recordID: id)
                    transactionRecord["buyerName"] = buyer.name
                    transactionRecord["receiverName"] = receiver.name
                    if let transaction = Transaction(record: transactionRecord) {
                        transactions.append(transaction)
                    }
                }
            }
        }
        return transactions
    }
}
