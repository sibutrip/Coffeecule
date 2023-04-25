//
//  VMPeople.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

extension ViewModel {
    
    public func joinCoffeecule() async {
        self.state = .loading
        await self.populateData()
        if self.personService.rootShare == nil {
            state = .noShareFound
            return
        }
        if self.participantName.isEmpty {
            print("name is empty")
            state = .nameFieldEmpty
            return
        }
        if self.people.contains(where: {
            $0.name == self.participantName
        }) {
            state = .nameAlreadyExists
            return
        }
        do {
            try await repository.fetchSharedContainer()
        } catch {
            state = .noSharedContainerFound
            return
        }
        let record = personService.createParticipantRecord(for: self.participantName, in: self.people)
        await personService.saveSharedRecord(record)
        self.people = personService.addPersonToCoffecule(self.participantName, to: self.people)
        print(people)
        self.hasShare = true
        self.state = .loaded
    }
    
    public func refreshData() async {
        self.state = .loading
        await populateData()
        self.state = .loaded
    }
    
    public func createCoffeecule() async {
        self.state = .loading
        await self.populateData()
        if self.personService.rootShare != nil {
            state = .culeAlreadyExists
            return
        }
        if self.participantName.isEmpty {
            state = .nameFieldEmpty
            return
        }
        if self.people.contains(where: {
            $0.name == self.participantName
        }) {
            state = .nameAlreadyExists
            return
        }
        if personService.rootShare != nil {
            state = .culeAlreadyExists
            return
        }
        let name = self.participantName
        let record = personService.createRootRecord(for: name, in: self.people)
        self.people = personService.createPeopleFromScratch(from: [self.participantName])
        await personService.savePrivateRecord(record)
        self.createDisplayedDebts()
        self.calculateBuyer()
        personService.rootShare = await personService.createRootShare()
        self.hasShare = true
        self.state = .loaded
    }
    
    public func shareCoffeecule() async {
        await personService.fetchOrCreateShare()
        self.hasShare = true
    }
    
    private func populateData() async {
        let (peopleNames, transactions, hasShare) = await personService.fetchRecords()
        var people = personService.createPeopleFromScratch(from: peopleNames)
        people = personService.createPeopleFromExisting(with: transactions, and: people)
        self.people = people
        print("received \(transactions.count) transactions")
        print("received \(peopleNames.count) people names")
        print("found a share: \(hasShare ? "yes" : "no")")
        self.hasShare = hasShare
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
            //            let sharedZone = try await Repository.shared.container.sharedCloudDatabase.allRecordZones()[0]
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
            if self.participantName == self.personService.rootRecord?.recordID.recordName {
                try await self.transactionService.saveTransactions(transactions, in: repository.container.privateCloudDatabase)
            } else {
                try await self.transactionService.saveTransactions(transactions, in: repository.container.sharedCloudDatabase)
            }
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
        print(debts)
    }
    
    public func shortenName(_ nameComponents: PersonNameComponents?) -> String {
        guard let nameComponents = nameComponents else { return "" }
        if let name = nameComponents.givenName, var famName = nameComponents.familyName {
            return "\(name) \(famName.removeFirst())."
        } else {
            return ""
        }
    }
}
