//
//  PersonError.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/22/23.
//

import Foundation
<<<<<<< HEAD

enum PersonError: LocalizedError {
    case couldntCreateRootRecord, couldntCreateParticipantRecord, couldntCreateRootShare
    var errorDescription: String? {
        switch self {
        case .couldntCreateRootRecord:
            "failed to create coffeecule"
        case .couldntCreateParticipantRecord:
            "failed to join coffeecule"
        case .couldntCreateRootShare:
            "failed to share coffeecule"
        }
    }
    var recoverySuggestion: String? {
        switch self {
        case .couldntCreateRootRecord:
            "tell cory to switch the beta to the production environment lmao"
        case .couldntCreateParticipantRecord:
            "tell cory to switch the beta to the production environment lmao"
        case .couldntCreateRootShare:
            "tell cory to switch the beta to the production environment lmao"
        }
    }
}
=======
>>>>>>> PersonService
