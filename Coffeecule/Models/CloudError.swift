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
            return "could not identify user"
        case .multipleSharedContainers:
            return "multiple shared containers found"
        case .accountStatus:
            return "could not verify account status"
        case .couldNotDetermine:
            return "CloudKit can’t determine the status of the user’s iCloud account."
        case .noAccount:
            return "The device doesn’t have an iCloud account."
        case .restricted:
            return "The system denies access to the user’s iCloud account."
        case .temporarilyUnavailable:
            return "The user’s iCloud account is temporarily unavailable."
        case .couldNotRetrieveRecords:
            return "could not retreive records"
        }
    }
    var recoverySuggestion: String? {
        switch self {
        case .userIdentity:
            return """
            One of three issues are possible:
            1. The device has an iCloud account but has iCloud Drive disabled.
            2. You're not connected to the internet
            3. The device has an iCloud account with restricted access.
            4. The device doesn’t have an iCloud account.
            """
        case .multipleSharedContainers:
            return "make sure you're only in 1 coffeecule!"
        case .accountStatus:
            return "could not verify account status. make sure you're logged into icloud"
        case .couldNotDetermine:
            return "please quit and reopen the app"
        case .noAccount:
            return "an iCloud account is needed to join a 'cule"
        case .restricted:
            return "enable system permissions to your iCloud account"
        case .couldNotRetrieveRecords:
            return "make sure you're connected to the internet"
        case .temporarilyUnavailable:
            return "make sure you're connected to the internet???"
        }
    }
}
