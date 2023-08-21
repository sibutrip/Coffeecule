//
//  Repository.swift
//  SharedContainer
//
//  Created by Cory Tripathy on 4/10/23.
//

import Foundation
import CloudKit

extension CKRecord: @unchecked Sendable { }
extension CKRecordZone: @unchecked Sendable { }

actor Repository {
    
    init() { }
    
    public func prepareRepo() async {
        do {
            await self.createZonesIfNeeded()
            try await self.fetchUserIdentity()
            try await self.fetchSharedContainer()
            try await self.requestAppPermission()
            try await self.accountStatus()
        } catch {
            debugPrint(error)
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
    nonisolated static public let container = CKContainer(identifier: "iCloud.com.CoryTripathy.Tryouts")
    static public var database = container.privateCloudDatabase
    public var currentZone: CKRecordZone {
        if let sharedZone = sharedZone {
            print("using shared zone")
            return sharedZone
        } else {
            print("using private zone")
            return privateZone
        }
    }
    private var privateZone = CKRecordZone(zoneName: "Coffeecule") // private zone
    private var sharedZone: CKRecordZone?
    public var appPermission: CKContainer.ApplicationPermissionStatus = .initialState
    public var accountStatus: CKAccountStatus = .couldNotDetermine
    
    public lazy var allZones = [privateZone,sharedZone].compactMap { $0 }
    
    // METHODS
    
    private func fetchSharedContainer() async throws {
        let sharedContainers = try await Self.container.sharedCloudDatabase.allRecordZones()
        if sharedContainers.count > 1 {
            print("ERROR: more than 1 shared container")
        } else if sharedContainers.count == 1 {
            self.sharedZone = sharedContainers[0]
        }
    }
    
    private func requestAppPermission() async throws {
        self.appPermission = try await Self.container.requestApplicationPermission(.userDiscoverability)
    }
    
    private func fetchUserIdentity() async throws {
        let id = try await Self.container.userRecordID()
        let returnedIdentity = try await Self.container.userIdentity(forUserRecordID: id)
        self.userIdentity = returnedIdentity
        if let returnedIdentity = returnedIdentity {
            self.userName = returnedIdentity.nameComponents!.formatted()
        }
    }
    
    private func accountStatus() async throws {
        self.accountStatus = try await Self.container.accountStatus()
    }
    
    public static var shareMetaData: CKShare.Metadata?
    
    public func acceptSharedContainer(with shareMetaData: CKShare.Metadata) async throws {
        try await Self.container.accept(shareMetaData)
        try await fetchSharedContainer()
    }
    
    
    // PERSON DATABASE METHODS
    private func createZonesIfNeeded() async {
        do {
            let (_,_) = try await Self.database.modifyRecordZones(saving: [self.privateZone], deleting: [])
        } catch {
            print("couldnt not create new zones")
        }
    }
    
    public func removeRootRecords() {
        self.rootShare = nil
        self.rootRecord = nil
    }
    
    public func share(_ share: CKShare?) {
        self.rootShare = share
    }
    
    public func rootRecord(_ record: CKRecord?) {
        self.rootRecord = record
    }
    
    public func transactions(_ transactions: [Transaction]) {
        self.transactions = transactions
    }
    
}
