//
//  VMTransactions.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

extension ViewModel {
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
        self.currentBuyer = mostDebted?.key ?? Person()
    }
    
    public func buyCoffee() async {
        enum BuyCoffeeError: Error {
            case missingMember
        }
        
        self.state = .loading
        
        if self.currentBuyer.name == "nobody" {
            return
        }
        var updatedPeople = [Relationship]()
        do {
            let relationships = self.relationships
            let currentBuyer = self.currentBuyer
            var transactions = [Transaction]()
            var buyer = relationships.first(where: { $0.person == currentBuyer })!
            //            let sharedZone = try await Repository.shared.container.sharedCloudDatabase.allRecordZones()[0]
            for receiver in relationships {
                var receiver = receiver
                if receiver.name != buyer.name {
                    var newBuyerDebt = buyer.coffeesOwed[receiver.person] ?? 0
//                    guard var newBuyerDebt = buyer.coffeesOwed[receiver.person] else {
//                        debugPrint("something is wrong...")
//                        debugPrint("could not find \(buyer.name) coffees owed for \(receiver.name)")
//                        throw BuyCoffeeError.missingMember
//                    }
                    if receiver.isPresent {
                        let transaction = await Transaction(buyer: buyer.name, receiver: receiver.name, in: repository)
                        transactions.append(transaction)
                        newBuyerDebt += 1
                        print("\(buyer.name) bought coffee for \(receiver.name)")
                    }
                    buyer.coffeesOwed[receiver.person] = newBuyerDebt
                    
                    var newReceiverDebt = receiver.coffeesOwed[buyer.person] ?? 0
//                    guard var newReceiverDebt = receiver.coffeesOwed[buyer.person] else {
//                        debugPrint("something is wrong...")
//                        debugPrint("could not find \(receiver.name) coffees owed for \(buyer.name)")
//                        throw BuyCoffeeError.missingMember
//                    }
                    if receiver.isPresent {
                        newReceiverDebt -= 1
                    }
                    receiver.coffeesOwed[buyer.person] = newReceiverDebt
                    updatedPeople.append(receiver)
                }
            }
            updatedPeople.append(buyer)
            self.relationships = updatedPeople
            print(transactions.count)
            let rootRecordName = await repository.rootRecord?["userID"] as? String
            //TODO: use repo.zone to see the user's current zone: private or shared
            if self.userID == rootRecordName {
                try await self.transactionService.saveTransactions(transactions, in: Repository.container.privateCloudDatabase)
            } else {
                try await self.transactionService.saveTransactions(transactions, in: Repository.container.sharedCloudDatabase)
            }
        } catch {
            debugPrint(error)
            fatalError()
        }
        self.state = .loaded
    }
    
    public func createDisplayedDebts() {
        let people = self.relationships
        var debts = [Person:Int]()
        let presentPeople: [Relationship] = people
            .filter { $0.isPresent }
        //            .map { $0.person }
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
//        print(debts)
    }
}

