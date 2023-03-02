//
//  CloudKitError.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/6/23.
//

import Foundation

enum CloudKitError: String, LocalizedError {
    case iCloudAccountNotFound
    case iCloudAccountNotDetermined
    case iCloudAccountRestricted
    case iCloudAccountUnknown
}
