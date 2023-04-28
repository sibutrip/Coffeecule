//
//  ViewModel.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit
import UIKit
import SwiftUI
import Combine

@MainActor
class ViewModel: ObservableObject {
    
    @AppStorage("hasCoffeecule") var hasCoffeecule = false {
        didSet {
            print("hasCoffeecule is now \(hasCoffeecule.description)")
        }
    }
    
    enum State: Equatable {
        
        case loading
        case loaded
        case noCoffeecule
        case noPermission
        case error
    }
    
    // MARK: - Cloud-related Properties
    
    /// State directly observable by our view.
    @Published var state: State = .loading
    
    let readWriter: ReadWritable
    
    @Published var people: [Person] = [] {
        didSet {
            // when no people, set user defaults to false
            if self.people.count < 1 {
                self.hasCoffeecule = false
            } else if self.people.count > 1 {
                self.hasCoffeecule = true
            }
        }
    }
    @Published var displayedDebts: [Person: Int] = [:]
    
    /// not a computed property because if people have the same debt it will recompute and randomize each time you access it :(
    func calculateBuyer() {
        if self.people.count == 1 {
            currentBuyer = Person(name: "nobody")
            return
        }
        
        let displayedDebts = displayedDebts.shuffled()
        let mostDebted = displayedDebts.max { first, second in
            if first.key.isPresent && second.key.isPresent {
                return first.value > second.value
            }
            return false
        }
        currentBuyer = mostDebted?.key ?? Person(name: "nobody")
        self.displayedDebts = self.createDisplayedDebts()
        self.state = .loaded
    }
    
    func createDisplayedDebts() -> [Person:Int] {
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
//        self.displayedDebts = debts
        print(debts)
        return debts
    }
    
    @Published var currentBuyer = Person(name: "nobody")
    
    /// this creates a transaction w/ a CKRecord and appends it to transactions
    private func createTransaction(buyer: Person, receiver: Person) -> Transaction {
        let id = CKRecord.ID(zoneID: Repository.shared.recordZone.zoneID)
        let transactionRecord = CKRecord(recordType: Repository.shared.recordType, recordID: id)
        transactionRecord["buyerName"] = buyer.name
        transactionRecord["receiverName"] = receiver.name
        return Transaction(record: transactionRecord)!
    }
    
    func buyCoffee() {
        self.state = .loading
        var transactions = [Transaction]()
        var updatedPeople = [Person]()
        var buyer = currentBuyer
        for receiver in people {
            var receiver = receiver
            if receiver.name != buyer.name {
                guard var newBuyerDebt = buyer.coffeesOwed[receiver.name] else {
                    debugPrint("something is wrong...")
                    debugPrint("could not find \(buyer.name) coffees owed for \(receiver.name)")
                    return
                }
                if receiver.isPresent {
                    let transaction = createTransaction(buyer: buyer, receiver: receiver)
                    transactions.append(transaction)
                    newBuyerDebt += 1
                    print("\(buyer.name) bought coffee for \(receiver.name)")
                }
                buyer.coffeesOwed[receiver.name] = newBuyerDebt
                
                
                guard var newReceiverDebt = receiver.coffeesOwed[buyer.name] else {
                    debugPrint("something is wrong...")
                    debugPrint("could not find \(receiver.name) coffees owed for \(buyer.name)")
                    return
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
        print(updatedPeople)
        ReadWrite.shared.writePeopleToDisk(updatedPeople)
        Task {
            await ReadWrite.shared.writeTransactionsToCloud(transactions)
        }
        Task {
            await ReadWrite.shared.writePeopleToCloud(updatedPeople)
        }
    }
    
    func createNewCoffeecule(for names: [String]) {
        var people = [Person]()
        for buyer in names {
            var newPerson = Person(name: buyer)
            for receiver in names {
                if receiver != buyer {
                    newPerson.coffeesOwed[receiver] = 0
                }
            }
            people.append(newPerson)
        }
        self.people = people.sorted()
        self.hasCoffeecule = true
    }
    
    
    init(readWriter: ReadWritable) {
        UserDefaults.standard.set(true, forKey: "areZonesCreated")
        self.state = .loading
        self.readWriter = readWriter
        
        Task {
            await self.initialize()
            let transactions = await ReadWrite.shared.readTransactionsFromCloud()
            self.people = ReadWrite.shared.transactionsToPeople(transactions, people: [.init(name: "cory"), .init(name: "tom"), .init(name: "ty"), .init(name: "tariq"), .init(name: "zoe")]).sorted()
//            createNewCoffeecule(for: ["cory","tom","ty","zoe","tariq"])
            
//#error("run the above line to re-make a cule.")
            self.calculateBuyer()
        }
        
//        Task(priority: .userInitiated) {
//            await initialize()
//            if let updatedPeople = await backgroundUpdateCloud() {
//                self.people = updatedPeople
//            }
//        }
        self.state = .loaded
    }
}

