//
//  ViewModel.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import Foundation
import CloudKit
//import UIKit
import SwiftUI

@MainActor
class ViewModel: ObservableObject {
    
    let repository = Repository.shared
    let personService = PersonService()
    let transactionService = TransactionService()
    var participantType: ParticipantType?
    var userID: String?
    
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
    @Published var relationships: [Relationships] = []
    @Published var currentBuyer = Person()
    @Published var displayedDebts: [Person:Int] = [:]
    @Published var hasShare = false {
        didSet {
            print("has share is \(hasShare)")
        }
    }
    
    init() {
        Task {
            do {
                let accountStatus = try await repository.container.accountStatus()
                let appPermissionStatus = try await repository.container.requestApplicationPermission(.userDiscoverability)
                switch appPermissionStatus {
                case .initialState:
                    state = .noPermission
                case .couldNotComplete:
                    state = .noPermission
                case .denied:
                    state = .noPermission
                case .granted:
                    switch accountStatus {
                    case .couldNotDetermine:
                        state = .noPermission
                    case .available:
                        self.userID = try await repository.container.userRecordID().recordName
                    case .restricted:
                        state = .noPermission
                    case .noAccount:
                        state = .noPermission
                    case .temporarilyUnavailable:
                        state = .noPermission
                    @unknown default:
                        fatalError()
                    }
                @unknown default:
                    fatalError()
                }
                try await self.initialize()
            } catch {
                print(error)
            }
        }
    }
}

