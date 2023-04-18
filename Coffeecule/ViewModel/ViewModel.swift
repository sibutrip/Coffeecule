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

@MainActor
class ViewModel: ObservableObject {
    
    @AppStorage("hasCoffeecule") var hasCoffeecule = false
    
    let repository = Repository.shared
    let personService = PersonService()
    let transactionService = TransactionService()
    
    enum State: Equatable {
        case loading, loaded, noCoffeecule, noPermission, error
    }
    
    @Published public var participantName: String = ""
//    @Published public var allRecords = [CKRecord]()
    @Published var state: State = .loading
    @Published var people: [Person] = []
    @Published var currentBuyer = Person(name: "nobody")
    @Published var displayedDebts: [Person:Int] = [:]
    @Published var hasShare = false
    
    public func onCoffeeculeLoad() async throws {
        self.state = .loading
        self.repository.userName = try await repository.fetchiCloudUserName()
        self.participantName = self.shortenName(repository.userName)
        await self.refreshData()
        if self.participantName == personService.rootRecord?.recordID.recordName {
            print("this is the owner")
        } else {
            print("this is not the owner")
            try! await self.repository.fetchSharedContainer()
        }
        self.createDisplayedDebts()
        self.calculateBuyer()
        self.state = .loaded
        print("participant name is \(self.participantName)")
    }
    
    init() {
        Task {
            self.state = .loading
            repository.userName = try! await self.repository.fetchiCloudUserName()
            self.participantName = self.shortenName(repository.userName)
            self.state = .loaded
            print(self.participantName)
        }
    }
}

