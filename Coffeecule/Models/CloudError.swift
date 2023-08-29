//
//  CloudError.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/22/23.
//

import Foundation

enum CloudError: LocalizedError {
    case userIdentity, multipleSharedContainers, accountStatus, couldNotDetermine, noAccount, restricted, temporarilyUnavailable, couldNotRetrieveRecords
    var errorDescription: String? {
        switch self {
        case .userIdentity:
            "could not identify user"
        case .multipleSharedContainers:
            "multiple shared containers found"
        case .accountStatus:
            "could not verify account status"
        case .couldNotDetermine:
            "CloudKit can’t determine the status of the user’s iCloud account."
        case .noAccount:
            "The device doesn’t have an iCloud account."
        case .restricted:
            "The system denies access to the user’s iCloud account."
        case .temporarilyUnavailable:
            "The user’s iCloud account is temporarily unavailable."
        case .couldNotRetrieveRecords:
            "could not retreive records"
        }
    }
    var recoverySuggestion: String? {
        switch self {
        case .userIdentity:
            """
            One of three issues are possible:
            1. The device has an iCloud account but the user disables iCloud Drive.
            2. The device has an iCloud account with restricted access.
            3. The device doesn’t have an iCloud account.
            """
        case .multipleSharedContainers:
            "make sure you're only in 1 coffeecule!"
        case .accountStatus:
            "could not verify account status. make sure you're logged into icloud"
        case .couldNotDetermine:
            "???"
        case .noAccount:
            "an iCloud account is needed to join a 'cule"
        case .restricted:
            "enable system permissions to your iCloud account"
        case .couldNotRetrieveRecords:
            "make sure you're connected to the internet"
        case .temporarilyUnavailable:
            "make sure you're connected to the internet???"
        }
    }
}
