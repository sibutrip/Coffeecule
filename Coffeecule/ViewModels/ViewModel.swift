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
    
    var currentBuyer = "nobody" {
        didSet {
            self.objectWillChange.send()
        }
    }
    @Published var presentPeopleDebt = [String:Int]()
    
    @AppStorage("coffeeculeMembers") var storedCoffeeculeMembers = Data()
    var coffeeculeMembers = ["cory","tariq","tom","ty","zoe"] {
        didSet {
            self.storedCoffeeculeMembers = JSONUtilitySTRUCT().encodeCoffeeculeMembers(for: self.coffeeculeMembers)
            print("added")
        }
    }
    
    var userHasCoffecule: Bool {
        coffeeculeMembers.count > 0
    }
    var transactions: [TransactionModel] = []
    var ARRAYcachedTransactions = [[String]]() {
        didSet {
            JSONUtilitySTRUCT().encodeCache(for: ARRAYcachedTransactions)
        }
    }
    
    var addedPeople = [String]()
    
    // MARK: - Init
    
    init() {
        state = .loading
        self.storedCoffeeculeMembers = JSONUtilitySTRUCT().encodeCoffeeculeMembers(for: self.coffeeculeMembers)
        coffeeculeMembers = JSONUtilitySTRUCT().decodeCoffeeculeMembers(for: storedCoffeeculeMembers)
        Task {
            self.relationshipWeb = try await populateWebFromCloud()
            state = .loaded
        }
    }
}
