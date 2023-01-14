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
//        case loaded(private: [Contact], shared: [Contact])
        case loaded
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
        
    var relationshipWeb = [String:BuyerInfo]() {
        didSet {
            currentBuyer = calculateCurrentBuyer(for: relationshipWeb)
        }
    }
        
    @Published var currentBuyer = "nobody"
    @Published var presentPeopleDebt = [String:Int]()
    
    @AppStorage("coffeeculeMembers") var coffeeculeMembersData: Data = Data()
    @AppStorage("userHasCoffecule") var userHasCoffecule = false
    
    let coffeeculeMembersList = ["cory","tariq","tom","ty","zoe"]
    let cloudContainer = "TransactionsTest"
    var transactions: [TransactionModel] = []

    var cachedTransactions = [[String]]() {
        didSet {
            JSONUtility().encodeCache(for: cachedTransactions)
        }
    }
    
    var addedPeople = [String]() {
        didSet { createNewCoffeecule(for: addedPeople) }
    }
    
    // MARK: - Init
    
    init() {
//        relationshipWeb = JSONUtility().decodeWeb()
//        relationshipWeb = generateRelationshipWeb(for: coffeeculeMembersList)
        state = .loading
        Task {
            try await populateWebFromCloud()
            state = .loaded
        }
    }
    
    func populateWebFromCloud() async throws {
            transactions = try await fetchTransactions(scope: .private, in: [recordZone])
            convertTransactionsToWeb(for: self.transactions)
    }
    

    
    public func createNewCoffeecule(for addedMembers: [String]) {
        #warning("this function does not work")
        generateRelationshipWeb(for: addedMembers)
        coffeeculeMembersData = JSONUtility().encodeCoffeeculeMembers(for: addedMembers)
        self.userHasCoffecule = true
    }
    
    func generateRelationshipWeb(for people: [String]) -> [String:BuyerInfo] {
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
//        self.relationshipWeb = relationshipWeb
        return relationshipWeb
    }
    
    enum RelationshipWebSource {
        case Cache, Cloud
    }
    
    func convertTransactionsToWeb(for transactions: [TransactionModel]) {
        var relationshipWeb = generateRelationshipWeb(for: coffeeculeMembersList)
        for transaction in transactions {
            relationshipWeb[transaction.buyerName]?.relationships[transaction.receiverName]! -= 1
            relationshipWeb[transaction.receiverName]?.relationships[transaction.buyerName]! += 1
        }
        self.relationshipWeb = relationshipWeb
    }
    
    func populateRelationshipWeb(from source: RelationshipWebSource) {
        switch source {
        case .Cloud:
            for transaction in transactions {
                //                print(transaction.buyerName)
                relationshipWeb[transaction.buyerName]?.relationships[transaction.receiverName]! -= 1
                relationshipWeb[transaction.receiverName]?.relationships[transaction.buyerName]! += 1
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
    
    
//    func buyCoffee() {
//        for presentPerson in presentPeople {
//            if presentPerson != currentBuyer {
//                relationshipWeb![currentBuyer]?.relationships[presentPerson]! -= 1
//                relationshipWeb![presentPerson]?.relationships[currentBuyer]! += 1
//                addItem(buyerName: currentBuyer, receiverName: presentPerson)
//                //                print("\(currentBuyer) bought a coffee bought for \(presentPerson)")
//            }
//        }
//        calculatePresentPeople()
//        calculateCurrentBuyer()
//        JSONUtility().encodeWeb(for: relationshipWeb!)
//        //        print(relationshipWeb)
//    }
    
}
