//
//  VMPeople.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

extension ViewModel {
    
    public func joinCoffeecule(name: String) async {
        do {
            self.hasCoffeecule = true
            let record = try await personService.createParticipantRecord(for: name, in: self.people)
            self.allRecords.append(record)
            await personService.saveSharedRecord(record)
            self.people = personService.addPersonToCoffecule(name, to: self.people)
            self.hasCoffeecule = true
        } catch {
            debugPrint(error)
        }
    }
    
    public func createCoffeecule() async {
        do {
            let name = self.participantName
            let record = try personService.createRootRecord(for: name, in: self.people)
            self.allRecords.append(record)
            self.people = personService.createPeopleFromScratch(from: [record])
            await personService.savePrivateRecord(record)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    public func shareCoffeecule() async {
        await personService.fetchOrCreateShare()
    }
    
    public func refreshData() async {
        let (peopleRecords, transactions, share) = await personService.fetchRecords()
        var people = personService.createPeopleFromScratch(from: peopleRecords)
        people = personService.createPeopleFromExisting(with: transactions, and: people)
        self.allRecords = peopleRecords
        self.people = people
        personService.rootShare = share
        print("received \(transactions.count) transactions")
        _ = transactions.map {
            print($0.buyerName,$0.receiverName)
        }
    }
    
    public func calculateBuyer() {
        let people = self.people
        let debts = self.displayedDebts
        if people.count == 1 {
            self.currentBuyer = Person(name: "nobody")
        }
        
        let mostDebted = debts.max { first, second in
            if first.key.isPresent && second.key.isPresent {
                return first.value > second.value
            }
            return false
        }
        self.currentBuyer = mostDebted?.key ?? Person(name: "nobody")
    }
    
    public func buyCoffee() async {
        enum BuyCoffeeError: Error {
            case missingMember
        }
        
        self.state = .loading
        
        if self.currentBuyer.name == "nobody" {
            return
        }
        var updatedPeople = [Person]()
        do {
            let people = self.people
            let currentBuyer = self.currentBuyer
            var transactions = [Transaction]()
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
                        if let transaction = Transaction(buyer: buyer.name, receiver: receiver.name) {
                            transactions.append(transaction)
                        }
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
            self.people = updatedPeople
            print(transactions.count)
            try await self.transactionService.saveTransactions(transactions)
        } catch {
            debugPrint(error)
            self.people = updatedPeople
        }
        self.state = .loaded
    }
    
    public func createDisplayedDebts() {
        let people = self.people
        var debts = [Person:Int]()
        let presentPeople: [Person] = people.filter {
            $0.isPresent
        }
        let presentNames: [String] = presentPeople.map {
            $0.name
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
        self.displayedDebts = debts
    }
    
}
