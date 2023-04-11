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
    
    public func calculateBuyer(for people: [Person], debts: [Person:Int]) -> Person {
        if people.count == 1 {
            return Person(name: "nobody")
        }
        
        let mostDebted = debts.max { first, second in
            if first.key.isPresent && second.key.isPresent {
                return first.value > second.value
            }
            return false
        }
        return mostDebted?.key ?? Person(name: "nobody")
    }
    
    public func buyCoffee(people: [Person], currentBuyer: Person) throws -> [Person] {
        enum BuyCoffeeError: Error {
            case missingMember
        }
        var transactions = [Transaction]()
        var updatedPeople = [Person]()
        var buyer = currentBuyer
        for receiver in people {
            var receiver = receiver
            if receiver.name != buyer.name {
                guard var newBuyerDebt = buyer.coffeesOwed[receiver.name] else {
                    debugPrint("something is wrong...")
                    debugPrint("could not find \(buyer.name) coffees owed for \(receiver.name)")
                    throw BuyCoffeeError.missingMember
                }
                if receiver.isPresent {
                    let transaction = Transaction.createTransaction(buyer: buyer, receiver: receiver)
                    transactions.append(transaction)
                    newBuyerDebt += 1
                    print("\(buyer.name) bought coffee for \(receiver.name)")
                }
                buyer.coffeesOwed[receiver.name] = newBuyerDebt
                
                
                guard var newReceiverDebt = receiver.coffeesOwed[buyer.name] else {
                    debugPrint("something is wrong...")
                    debugPrint("could not find \(receiver.name) coffees owed for \(buyer.name)")
                    throw BuyCoffeeError.missingMember
                }
                if receiver.isPresent {
                    newReceiverDebt -= 1
                }
                receiver.coffeesOwed[buyer.name] = newReceiverDebt
                updatedPeople.append(receiver)
            }
        }
        updatedPeople.append(buyer)
        return updatedPeople
    }
    
    public func createDisplayedDebts(people: [Person]) -> [Person:Int] {
        var debts = [Person:Int]()
        let presentPeople: [Person] = people.filter {
            $0.isPresent
        }
        let presentNames: [String] = presentPeople.map {
            $0.name.lowercased()
        }
        for person in presentPeople {
            let debt: Int = person.coffeesOwed.reduce(0) { partialResult, dict in
                if presentNames.contains(dict.key) {
                    return partialResult + dict.value
                }
                return 0 + partialResult
            }
            debts[person] = debt
        }
        return debts
    }
    
    public func saveTransaction(_ transaction: Transaction) async throws {
        if let zone = self.repository.sharedCoffeeculeZone {
            let record = CKRecord(recordType: transactionRecordName, recordID: CKRecord.ID(recordName: transaction.id, zoneID: zone.zoneID))
            let _ = try await repository.container.sharedCloudDatabase.modifyRecords(saving: [record], deleting: [])
        }
    }
    
    func createPeople(from transactions: [Transaction], and people: [Person]) -> [Person] {
        // create blank people template
        var peopleToAdd = people
            .map { $0.name }
            .map { Person(name: $0) }
        
        for transaction in transactions {
            let buyer = transaction.buyerName
            let receiver = transaction.receiverName
            peopleToAdd = incrementDebt(buyer: buyer, receiver: receiver, in: peopleToAdd)
            peopleToAdd = decrementDebt(buyer: buyer, receiver: receiver, in: peopleToAdd)
        }
        return peopleToAdd
    }
    
    private func incrementDebt(buyer: String, receiver: String, in peopleToAdd: [Person]) -> [Person] {
        var peopleToAdd = peopleToAdd
        guard let buyerIndex = peopleToAdd.firstIndex(where: {
            $0.name == buyer
        }) else {
            debugPrint("transaction buyer: \(buyer) is not in the people array")
            return [Person]()
        }
        
        var newBuyerDebt = peopleToAdd[buyerIndex].coffeesOwed[receiver] ?? 0
        newBuyerDebt += 1
        peopleToAdd[buyerIndex].coffeesOwed[receiver] = newBuyerDebt
        return peopleToAdd
    }
    
    private func decrementDebt(buyer: String, receiver: String, in peopleToAdd: [Person]) -> [Person] {
        var peopleToAdd = peopleToAdd
        guard let receiverIndex = peopleToAdd.firstIndex(where: {
            $0.name == receiver
        }) else {
            debugPrint("transaction receiver: \(receiver) is not in the people array")
            return [Person]()
        }
        
        var newReceiverDebt = peopleToAdd[receiverIndex].coffeesOwed[buyer] ?? 0
        newReceiverDebt -= 1
        peopleToAdd[receiverIndex].coffeesOwed[buyer] = newReceiverDebt
        return peopleToAdd
    }
}
