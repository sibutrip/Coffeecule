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
    let recordType = "Corycule"

        
//    var coffeeculeMembers: [String] { self.relationshipWeb.keys.sorted() }
    var relationshipWeb = [String:BuyerInfo]() {
        didSet {
            currentBuyer = calculateCurrentBuyer(for: relationshipWeb)
        }
    }
        
//    @Published
    var currentBuyer = "nobody" {
        didSet {
            self.objectWillChange.send()
        }
    }
    @Published var presentPeopleDebt = [String:Int]()
    
    @AppStorage("coffeeculeMembers") var coffeeculeMembersData: Data = Data()
    @AppStorage("userHasCoffecule") var userHasCoffecule = false
    @Published var userHasCoffeeculeOnLaunch = false
    
    var coffeeculeMembers = ["cory","tariq","tom","ty","zoe"]
    var transactions: [TransactionModel] = []
    var cachedRecords = [String:CKRecord]()
    var ARRAYcachedTransactions = [[String]]() {
        didSet {
            JSONUtility().encodeCache(for: ARRAYcachedTransactions)
        }
    }
    
    var addedPeople = [String]() {
        didSet { createNewCoffeecule(for: addedPeople) }
    }
    
    // MARK: - Init
    
    init() {
//        relationshipWeb = JSONUtility().decodeWeb()
//        relationshipWeb = generateRelationshipWeb(for: coffeeculeMembersList)
        userHasCoffeeculeOnLaunch = true
        state = .loading
        Task {
            self.relationshipWeb = try await populateWebFromCloud()
            state = .loaded
        }
        if ARRAYcachedTransactions.count > 0 {
            print("there are \(ARRAYcachedTransactions.count) cached transaactions")
        }
    }
    
    func populateWebFromCloud() async throws -> [String:BuyerInfo] {
        let transactionsTask = Task { () -> [String:BuyerInfo] in
            let populatedTransactions = try await fetchTransactions(scope: .private, in: [recordZone])
            return convertTransactionsToWeb(for: populatedTransactions)
        }
        let transactions = await transactionsTask.result
        return try transactions.get()
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
    
    func convertTransactionsToWeb(for transactions: [TransactionModel]) -> [String:BuyerInfo]{
        var relationshipWeb = generateRelationshipWeb(for: coffeeculeMembers)
        for transaction in transactions {
            print(transaction.buyerName,transaction.receiverName)
            relationshipWeb[transaction.buyerName]?.relationships[transaction.receiverName]! -= 1
            relationshipWeb[transaction.receiverName]?.relationships[transaction.buyerName]! += 1
        }
        return relationshipWeb
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
