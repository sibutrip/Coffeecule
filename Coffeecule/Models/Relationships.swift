//
//  Relationship.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 6/2/23.
//

import Foundation

struct Relationships {
    let person: Person
    var name: String {
        person.name
    }
    var coffeesOwed: [Person:Int] = [:]
    var isPresent = false
    
    static var all = [Relationships]()
    
    static public func addPerson(_ person: Person) {
        Self.all = Self.updateRelationships(adding: person)
    }
    
    static public func populateRelationships(with transaction: Transaction) {
        //TODO: functions to populate with transactions
    }
    
    private static func updateRelationships(adding person: Person) -> [Relationships] {
        var updatedRelationships = [Relationships]()
        let previousRelationships = Self.all
        var newRelationship = Relationships(person)
        for previousRelationship in previousRelationships {
            var previousRelationship = previousRelationship
            newRelationship.coffeesOwed[previousRelationship.person] = 0
            previousRelationship.coffeesOwed[person] = 0
            updatedRelationships.append(previousRelationship)
        }
        updatedRelationships.append(newRelationship)
        return updatedRelationships
    }
    
    init(_ person: Person) {
        self.person = person
    }
}
