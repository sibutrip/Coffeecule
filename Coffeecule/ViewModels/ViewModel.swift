//
//  ViewModel.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/12/23.
//

import Foundation
import SwiftUI
import CloudKit

@MainActor
class ViewModel: ObservableObject {
    
    // MARK: - Error

    enum ViewModelError: Error {
        case invalidRemoteShare
    }

    // MARK: - State

    enum State {
        case loading
        case loaded(private: [Contact], shared: [Contact])
        case error(Error)
    }

    
    // MARK: - Properties

    /// State directly observable by our view.
    @Published var state: State = .loading
    /// Use the specified iCloud container ID, which should also be present in the entitlements file.
    lazy var container = CKContainer(identifier: Config.containerIdentifier)
    /// This project uses the user's private database.
    lazy var database = container.privateCloudDatabase
    /// Sharing requires using a custom record zone.
    let recordZone = CKRecordZone(zoneName: "Transactions")
    
    // MARK: - Init

//    nonisolated init() {}

    /// Initializer to provide explicit state (e.g. for previews).
    ///
//    init(state: State) {
//        self.state = state
//    }
    
    var relationshipWeb: [String:BuyerInfo]? = nil
    {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    @AppStorage("coffeeculeMembers") var coffeeculeMembersData: Data = Data()
    @AppStorage("userHasCoffecule") var userHasCoffecule = false
    var cloudContainer = "TransactionsTest"
    var isConnectedToCloud = false
    var cachedTransactions = [[String]]() {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    var webIsPopulated = false
//    var cachedTransactions = [["Tariq","Cory"]]
    var userHasCoffeeculeOnLaunch = false
    var addedPeople = [String]() {
        didSet {
            createNewCoffeecule(for: addedPeople)
        }
    }
    @Published var transactions: [TransactionModel] = []
    
    init() {
        userHasCoffeeculeOnLaunch = userHasCoffecule
        if userHasCoffecule {
            let people = JSONUtility().decodeCoffeeculeMembers(for: coffeeculeMembersData)
            generateRelationshipWeb(for: people)
            // create empty web. will populate later with cached web or icloud transactions
            checkiCloudStatus()
        }
    }
    
    var presentPeople = [String]()
    
    var presentPeopleDebt: [String:Int]
    {
        var presentPeopleDebt = [String:Int]()
        for giverName in presentPeople {
            var individualDebtCount = 0
            for receiverName in relationshipWeb![giverName]!.relationships {
                if presentPeople.contains(receiverName.key) {
                    individualDebtCount += receiverName.value
                }
            }
            presentPeopleDebt[giverName] = individualDebtCount
        }
        return presentPeopleDebt
    }
    
    var currentBuyer = "nobody"
    
    func calculatePresentPeopleDebt() {
        var presentPeopleDebt = [String:Int]()
        for giverName in presentPeople {
            var individualDebtCount = 0
            if let relationshipWeb = relationshipWeb {
                if let buyerInfo = relationshipWeb[giverName] {
                    for receiverName in buyerInfo.relationships {
                        if presentPeople.contains(receiverName.key) {
                            individualDebtCount += receiverName.value
                        }
                    }
                }
            }
            presentPeopleDebt[giverName] = individualDebtCount
        }
        //        self.presentPeopleDebt = presentPeopleDebt
//        print(presentPeopleDebt)
    }
    
    
    public func createNewCoffeecule(for addedMembers: [String]) {
        generateRelationshipWeb(for: addedMembers)
        coffeeculeMembersData = JSONUtility().encodeCoffeeculeMembers(for: addedMembers)
        self.userHasCoffecule = true
    }
    
    func generateRelationshipWeb(for people: [String]) {
        /// creates empty web template
        var relationshipWeb = [String:BuyerInfo]()
        for buyer in people {
            var buyerInfo = BuyerInfo()
            for receiver in people {
                if receiver != buyer {
                    buyerInfo.relationships[receiver] = 0
                }
            }
            relationshipWeb[buyer] = buyerInfo
        }
//        JSONUtility().encodeWeb(for: relationshipWeb)
        self.relationshipWeb = relationshipWeb
    }
    
    enum RelationshipWebSource {
        case Cache, Cloud
    }
    
    func populateRelationshipWeb(from source: RelationshipWebSource) {
        switch source {
        case .Cloud:
            for transaction in transactions {
//                print(transaction.buyerName)
                relationshipWeb?[transaction.buyerName]?.relationships[transaction.receiverName]! -= 1
                relationshipWeb?[transaction.receiverName]?.relationships[transaction.buyerName]! += 1
            }
        case .Cache:
            self.relationshipWeb = JSONUtility().decodeWeb()
//            print("loaded from cache")
//            print(self.relationshipWeb)
//            print(relationshipWeb)
//            for transaction in cachedTransactions {
//                relationshipWeb?[transaction[0]]?.relationships[transaction[1]]! -= 1
//                relationshipWeb?[transaction[1]]?.relationships[transaction[0]]! -= 1
//                print("cached transaction added to web")
//            }
        }
//        webIsPopulated = true
    }
    
    func calculateCurrentBuyer() {
        let sortedPeople = presentPeopleDebt.sorted { $0.1 > $1.1 }
        currentBuyer = sortedPeople.first?.key ?? "nobody"
    }
    
    func calculatePresentPeople() {
        var nextPresentPeople = [String]()
        for person in relationshipWeb! {
            if person.value.isPresent {
                nextPresentPeople.append(person.key)
            }
        }
        presentPeople = nextPresentPeople
    }
    
    func buyCoffee() {
        for presentPerson in presentPeople {
            if presentPerson != currentBuyer {
                relationshipWeb![currentBuyer]?.relationships[presentPerson]! -= 1
                relationshipWeb![presentPerson]?.relationships[currentBuyer]! += 1
                addItem(buyerName: currentBuyer, receiverName: presentPerson)
//                print("\(currentBuyer) bought a coffee bought for \(presentPerson)")
            }
        }
        calculatePresentPeople()
        calculateCurrentBuyer()
        JSONUtility().encodeWeb(for: relationshipWeb!)
//        print(relationshipWeb)
    }
    
}
