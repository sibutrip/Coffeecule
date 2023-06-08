//
//  Repository.swift
//  SharedContainer
//
//  Created by Cory Tripathy on 4/10/23.
//

import Foundation
import CloudKit

class Repository {
    
    init() {
        Task {
            do {
                await self.createZonesIfNeeded()
                self.appPermission = try await self.requestAppPermission()
                self.accountStatus = try await self.container.accountStatus()
                try await self.fetchUserIdentity()
                try await self.fetchSharedContainer()
                
            } catch {
                debugPrint(error)
            }
        }
    }
    
    // RECORDS
    public var transactions: [Transaction]?
    public var rootRecord: CKRecord? = nil
    public var rootShare: CKShare? = nil
        
    
    // USER
    public var userIdentity: CKUserIdentity?
    public var userName: String?
    
    // CONTAINER
    public let container = CKContainer(identifier: "iCloud.com.CoryTripathy.Tryouts")
    public lazy var database = container.privateCloudDatabase
    public var currentZone: CKRecordZone {
        if let sharedZone = sharedZone {
            return sharedZone
        } else {
            return privateZone
        }
    }
    private var privateZone = CKRecordZone(zoneName: "Coffeecule") // private zone
    private var sharedZone: CKRecordZone?
    public var appPermission: Bool? = nil
    public var accountStatus: CKAccountStatus? = nil
    
    public lazy var allZones = [privateZone,sharedZone].compactMap { $0 }
    
    // METHODS
    
    public func fetchSharedContainer() async throws {
        let sharedContainers = try await self.container.sharedCloudDatabase.allRecordZones()
        if sharedContainers.count > 1 {
            print("ERROR: more than 1 shared container")
        } else if sharedContainers.count == 1 {
            self.sharedZone = sharedContainers[0]
        }
    }
    
    public func requestAppPermission() async throws -> Bool {
        enum AppPermissionError: Error {
            case noPermission,couldNotComplete,denied,granted, unknown
        }
        let permission = try await self.container.requestApplicationPermission(.userDiscoverability)
        switch permission {
        case .initialState:
            throw AppPermissionError.noPermission
        case .couldNotComplete:
            throw AppPermissionError.couldNotComplete
        case .denied:
            throw AppPermissionError.denied
        case .granted:
            return true
        @unknown default:
            throw AppPermissionError.unknown
        }
    }
    
    public func fetchUserIdentity() async throws {
        let id = try await self.container.userRecordID()
        let returnedIdentity = try await self.container.userIdentity(forUserRecordID: id)
        self.userIdentity = returnedIdentity
        if let returnedIdentity = returnedIdentity {
            self.userName = returnedIdentity.nameComponents!.formatted()
        }
    }
    
    // PERSON DATABASE METHODS
    private func createZonesIfNeeded() async {
        do {
            let (_,_) = try await self.database.modifyRecordZones(saving: [self.privateZone], deleting: [])
        } catch {
            print("couldnt not create new zones")
        }
    }
    
    static let shared = Repository()
}
