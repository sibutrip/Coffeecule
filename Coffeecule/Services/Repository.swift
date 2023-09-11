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

actor Repository: ObservableObject {
    
    init() { }
    
    public func prepareRepo() async throws {
        await self.createZonesIfNeeded()
        try await self.accountStatus()
        try await self.fetchUserIdentity()
        try await self.fetchSharedContainer()
    }
    
    
    // RECORDS
    @Published public var transactions: [Transaction]? {
        didSet {
            print(transactions?.count)
        }
    }
    public var rootRecord: CKRecord? = nil
    public var rootShare: CKShare? = nil
    public static var shareMetaData: CKShare.Metadata?
    
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
    public var privateZone = CKRecordZone(zoneName: "Coffeecule") // private zone
    private var sharedZone: CKRecordZone?
    public var appPermission: CKContainer.ApplicationPermissionStatus = .initialState
    //    public var accountStatus: CKAccountStatus = .couldNotDetermine
    
    public lazy var allZones = [privateZone,sharedZone].compactMap { $0 }
    
    // METHODS
    
    private func fetchSharedContainer() async throws {
        guard let sharedContainers = try? await Self.container.sharedCloudDatabase.allRecordZones() else {
            return
        }
        if sharedContainers.count > 1 {
            throw CloudError.multipleSharedContainers
        } else if sharedContainers.count == 1 {
            self.sharedZone = sharedContainers[0]
        }
    }
    
    //    private func requestAppPermission() async throws {
    //        self.appPermission = try await Self.container.requestApplicationPermission(.userDiscoverability)
    //    }
    
    private func fetchUserIdentity() async throws {
        do {
            let id = try await Self.container.userRecordID()
            let returnedIdentity = try await Self.container
                .shareParticipant(forUserRecordID: id)
                .userIdentity
            self.userIdentity = returnedIdentity
            self.userName = returnedIdentity.nameComponents!.formatted()
        }
        catch {
            throw CloudError.userIdentity
        }
    }
    
    private func accountStatus() async throws {
        do {
            let accountStatus = try await Self.container.accountStatus()
            switch accountStatus {
            case .couldNotDetermine:
                throw CloudError.couldNotDetermine
            case .noAccount:
                throw CloudError.noAccount
            case .restricted:
                throw CloudError.restricted
            case .temporarilyUnavailable:
                throw CloudError.temporarilyUnavailable
            case .available:
                break
            @unknown default:
                break
            }
        } catch {
            throw CloudError.accountStatus
        }
    }
        
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
    
    public func setTransactions(_ transactions: [Transaction]) {
        self.transactions = transactions
    }
    
    public func addTransactions(_ transactions: [Transaction]) {
        if let existingTransactions = self.transactions {
            self.transactions = existingTransactions + transactions
        } else {
            self.transactions = transactions
        }
    }
    public func remove(transaction: Transaction) {
        self.transactions = self.transactions?.filter {
            $0.id != transaction.id
        }
    }
}
