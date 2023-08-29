//
//  PersonError.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/22/23.
//

import Foundation

enum PersonError: Error, LocalizedError {
    case couldntCreateRootRecord, couldntCreateParticipantRecord, couldntCreateRootShare, alreadyOwnsCoffeecule, multipleCoffeeculesExist
    var errorDescription: String? {
        switch self {
        case .couldntCreateRootRecord:
            "failed to create coffeecule"
        case .couldntCreateParticipantRecord:
            "failed to join coffeecule"
        case .couldntCreateRootShare:
            "failed to share coffeecule"
        case .alreadyOwnsCoffeecule:
            "failed to ?? coffeecule"
        case .multipleCoffeeculesExist:
            "failed to ?? coffeecule"
        }
    }
    var recoverySuggestion: String? {
        switch self {
        case .couldntCreateRootRecord:
            "tell cory to switch the beta to the production environment lmao"
        case .couldntCreateParticipantRecord:
            "tell cory to switch the beta to the production environment lmao"
        case .alreadyOwnsCoffeecule:
            "delete your current coffeecule before joining another"
        case .multipleCoffeeculesExist:
            "contact your local dev, you're in multiple coffeecules"
        case .couldntCreateRootShare:
            "tell cory to switch the beta to the production environment lmao"
        }
    }
}
