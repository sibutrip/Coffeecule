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
                let sharedContainers = try await self.container.sharedCloudDatabase.allRecordZones()
                if sharedContainers.count > 0 {
                    self.sharedCoffeeculeZone = sharedContainers[0]
                } else if sharedContainers.count > 1 {
                    print("ERROR: more than 1 shared container")
                }
            } catch {
                debugPrint(error)
            }
        }
    }
    
    
    
    // PUBLIC
    public let container = CKContainer(identifier: "iCloud.com.CoryTripathy.Tryouts")
    public lazy var database = container.privateCloudDatabase
    public let coffeeculeRecordZone = CKRecordZone(zoneName: "PersonZone") // private zone
    public var sharedCoffeeculeZone: CKRecordZone? = nil
    public var appPermission: Bool? = nil
    public var accountStatus: CKAccountStatus? = nil
    
    // APP PERMISSION
    
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
    
    public func fetchiCloudUserName() async throws -> String {
        let id = try await self.container.userRecordID()
        let returnedIdentity = try await self.container.userIdentity(forUserRecordID: id)
        if let name = returnedIdentity?.nameComponents?.givenName, var famName = returnedIdentity?.nameComponents?.familyName {
            return "\(name) \(famName.removeFirst())."
        } else {
            print("could not unwrap name")
        }
        return ""
    }
    
    // PERSON DATABASE METHODS
    private func createZonesIfNeeded() async {
        do {
            let (_,_) = try await self.database.modifyRecordZones(saving: [self.coffeeculeRecordZone], deleting: [])
        } catch {
            print("couldnt not create new zones")
        }
        UserDefaults.standard.set(true, forKey: "areZonesCreated")
    }
    
    static let shared = Repository()
}
