//
//  VMTransactions.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

extension ViewModel {
    
    public func buyCoffee(buyer: Person, receivers: [Person]) {
        
    }
    public func calculateBuyer() {
        let relationships = self.relationships
        let debts = self.displayedDebts
        if relationships.count == 1 {
            self.currentBuyer = Person()
        }
        
        let mostDebted = debts.max { first, second in
            let firstPerson = relationships.first { $0.person == first.key }
            let secondPerson = relationships.first { $0.person == second.key }
            if firstPerson!.isPresent && secondPerson!.isPresent {
                return first.value > second.value
            }
            return false
        }
        let presentPeopleCount = relationships.filter { $0.isPresent }.count
        guard presentPeopleCount > 1 else {
            self.currentBuyer = Person()
            return
        }
        self.currentBuyer = mostDebted?.key ?? Person()
    }
    
    public func buyCoffee(buyer: Person? = nil, receivers: Set<Person>) async {
        if self.currentBuyer.name == "nobody" {
            return
        }
        var updatedPeople = [Relationship]()
        do {
            let relationships = self.relationships
            let currentBuyer = buyer ?? self.currentBuyer
            var transactions = [Transaction]()
            var buyer = relationships.first(where: { $0.person == currentBuyer })!
            for receiver in relationships {
                var receiver = receiver
                if receiver.name != buyer.name {
                    let receiverIsSelected = receivers.contains(where: {$0 == receiver.person} )
                    var newBuyerDebt = buyer.coffeesOwed[receiver.person] ?? 0
                    if receiverIsSelected {
                        let transaction = await Transaction(buyer: buyer.name, receiver: receiver.name, in: repository)
                        transactions.append(transaction)
                        newBuyerDebt += 1
                        print("\(buyer.name) bought coffee for \(receiver.name)")
                    }
                    buyer.coffeesOwed[receiver.person] = newBuyerDebt
                    
                    var newReceiverDebt = receiver.coffeesOwed[buyer.person] ?? 0
                    if receiverIsSelected {
                        newReceiverDebt -= 1
                    }
                    receiver.coffeesOwed[buyer.person] = newReceiverDebt
                    updatedPeople.append(receiver)
                }
            }
            updatedPeople.append(buyer)
            self.relationships = updatedPeople.sorted()
            let rootRecordName = await repository.rootRecord?["userID"] as? String
            if self.userID == rootRecordName {
                try await self.transactionService.saveTransactions(transactions, in: Repository.container.privateCloudDatabase)
            } else {
                try await self.transactionService.saveTransactions(transactions, in: Repository.container.sharedCloudDatabase)
            }
        } catch {
            debugPrint(error)
            fatalError()
        }
    }
    
    public func createDisplayedDebts() {
        let people = self.relationships
        var debts = [Person:Int]()
        let presentPeople: [Relationship] = people
            .filter { $0.isPresent }
        let presentNames: [String] = presentPeople.map {
            $0.name
        }
        for relationship in presentPeople {
            let debt: Int = relationship.coffeesOwed.reduce(0) { partialResult, dict in
                if presentNames.contains(dict.key.name) {
                    return partialResult + dict.value
                }
                return 0 + partialResult
            }
            debts[relationship.person] = debt
        }
        self.displayedDebts = debts
    }
}

