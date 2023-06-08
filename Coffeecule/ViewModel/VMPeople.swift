//
//  VMPeople.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

extension ViewModel {
    
    public func createCoffeecule() async throws {
        self.state = .loading
        await self.populateData()
        if self.repository.rootShare != nil {
            state = .culeAlreadyExists
            return
        }
        if self.participantName.isEmpty {
            state = .nameFieldEmpty
            return
        }
        if self.relationships.contains(where: {
            $0.name == self.participantName
        }) {
            state = .nameAlreadyExists
            return
        }
        if repository.rootShare != nil {
            state = .culeAlreadyExists
            return
        }
        
        let person = Person(name: self.participantName, participantType: .root)
        self.relationships = Relationships.addPerson(person)
        self.hasShare = await personService.createRootShare()
        try await personService.saveRecord(person.associatedRecord, participantType: .root)
        
        self.state = .loaded
        self.createDisplayedDebts()
        self.calculateBuyer()
        self.state = .loaded
    }
    
    public func joinCoffeecule() async throws {
        self.state = .loading
        await self.populateData()
        if self.repository.rootShare == nil {
            state = .noShareFound
            return
        }
        if self.participantName.isEmpty {
            print("name is empty")
            state = .nameFieldEmpty
            return
        }
        if self.relationships.contains(where: {
            $0.name == self.participantName
        }) {
            state = .nameAlreadyExists
            return
        }
        let person = Person(name: self.participantName, participantType: .participant)
        try await personService.saveRecord(person.associatedRecord, participantType: .participant)
        self.relationships = Relationships.addPerson(person)
        self.state = .loaded
    }
    
    public func refreshData() async {
        await populateData()
    }
    
    public func loadData() async {
        self.state = .loading
        await populateData()
        self.state = .loaded
    }
    
    public func shareCoffeecule() async {
        self.hasShare = await personService.fetchOrCreateShare()
    }
    
    private func populateData() async {
        do {
            let (fetchedPeople, transactions, hasShare) = try await personService.fetchRecords()
            self.relationships = Relationships.populatePeople(with: fetchedPeople)
            transactions.forEach { Relationships.populateRelationships(with: $0) }
            print("received \(transactions.count) transactions")
            print("received \(fetchedPeople.count) people")
            print("found a share: \(hasShare ? "yes" : "no")")
            self.hasShare = hasShare
        } catch {
            print(error.localizedDescription)
        }
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
        var updatedPeople = [Relationships]()
        do {
            let relationships = self.relationships
            let currentBuyer = self.currentBuyer
            var transactions = [Transaction]()
            var buyer = relationships.first(where: { $0.person == currentBuyer })!
            //            let sharedZone = try await Repository.shared.container.sharedCloudDatabase.allRecordZones()[0]
            for receiver in relationships {
                var receiver = receiver
                if receiver.name != buyer.name {
                    guard var newBuyerDebt = buyer.coffeesOwed[receiver.person] else {
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
                    buyer.coffeesOwed[receiver.person] = newBuyerDebt
                    
                    
                    guard var newReceiverDebt = receiver.coffeesOwed[buyer.person] else {
                        debugPrint("something is wrong...")
                        debugPrint("could not find \(receiver.name) coffees owed for \(buyer.name)")
                        throw BuyCoffeeError.missingMember
                    }
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
            if self.participantName == repository.rootRecord?.recordID.recordName {
                try await self.transactionService.saveTransactions(transactions, in: repository.container.privateCloudDatabase)
            } else {
                try await self.transactionService.saveTransactions(transactions, in: repository.container.sharedCloudDatabase)
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
        let presentPeople: [Relationships] = people
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
    
    public func deleteCoffeecule() async throws {
        try await personService.deleteAllTransactions()
        try await personService.deleteAllUsers(relationships)
        try await personService.deleteShare()
        self.hasShare = false
        self.relationships.removeAll()
        self.repository.rootShare = nil
        self.repository.rootRecord = nil
    }
}
