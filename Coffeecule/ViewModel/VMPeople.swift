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
            let record = try await personService.createParticipantRecord(for: name, in: self.people)
            self.allRecords.append(record)
            await personService.saveSharedRecord(record)
            self.people = personService.addPersonToCoffecule(name, to: self.people)
            print(self.people)
        } catch {
            debugPrint(error)
        }
    }
    
    public func createCoffeecule(name: String) async {
        do {
            let record = try personService.createRootRecord(for: name, in: self.people)
            self.allRecords.append(record)
            await personService.savePrivateRecord(record)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    public func shareCoffeecule() async {
        await personService.fetchOrCreateShare()
    }
    
    public func refreshData() async {
        var (peopleRecords, transactions, share) = await personService.fetchRecords(scope: .shared)
        peopleRecords.append(contentsOf: await personService.fetchPrivatePeople())
        var people = personService.createPeopleFromScratch(from: peopleRecords)
        people = personService.createPeopleFromExisting(with: transactions, and: people)
        self.allRecords = peopleRecords
        self.people = people
        personService.rootShare = share
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
    
    public func buyCoffee() {
        enum BuyCoffeeError: Error {
            case missingMember
        }
        
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
        } catch {
            debugPrint(error)
        }
        self.people = updatedPeople
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
        print(debts)
        self.displayedDebts = debts
    }
}
