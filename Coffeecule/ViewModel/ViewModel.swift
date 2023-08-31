//
//  ViewModel.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit
import SwiftUI

@MainActor
class ViewModel: ObservableObject {
    
    var repository: Repository
    var personService: PersonService
    let transactionService = TransactionService()
    let relationshipService = RelationshipService()
    var participantType: ParticipantType?
    var userID: String?
    @Published var cloudError: CloudError?
    @Published var cloudAuthenticationDidFail = false
    
    @Published var personError: PersonError?
    @Published var personRecordCreationDidFail = false

    
    enum State: String, Equatable, LocalizedError {
        case loading
        case loaded
        case noPermission = "app does not have permission to use your iCloud"
        case nameFieldEmpty = "name field is empty"
        case nameAlreadyExists = "name already exists in this coffeecule"
        case noShareFound = "could not find cule. make sure you open an invite the owner has shared"
        case noSharedContainerFound = "internal error: could not find shared data"
        case culeAlreadyExists = "cannot create cule. you already have one"
    }
    
    @Published public var participantName: String = ""
    @Published var state: State = .loading {
        didSet {
            print(self.state)
        }
    }
    @Published var relationships: [Relationship] = [] {
        didSet {
            createDisplayedDebts()
            calculateBuyer()
        }
    }
    @Published var currentBuyer = Person()
    @Published var displayedDebts: [Person:Int] = [:]
    @Published var hasShare = false {
        didSet {
            print("has share is \(hasShare)")
        }
    }
    
    func assignUserID() async throws {
        let id = try await Repository.container.userRecordID().recordName
        self.userID = id
        try await self.initialize()
    }
    
    init() {
        self.state = .loading
        repository = Repository()
        self.personService = PersonService(with: self.repository)
        Task {
            do {
                try await self.repository.prepareRepo()
                try await self.loadData()
            } catch (let cloudError) {
                self.cloudError = cloudError as? CloudError
                cloudAuthenticationDidFail = true
                print(cloudError.localizedDescription)
            }
//            relationships = [
//            Relationship(Person(name: "Cory", associatedRecord: CKRecord(recordType: "test"))),
//            Relationship(Person(name: "Tom", associatedRecord: CKRecord(recordType: "test"))),
//            Relationship(Person(name: "Ty", associatedRecord: CKRecord(recordType: "test")))
//            ]
//            relationships[0].coffeesOwed[relationships[1].person] = 1
//            relationships[1].coffeesOwed[relationships[0].person] = -1
            self.state = .loaded
        }
    }
}

