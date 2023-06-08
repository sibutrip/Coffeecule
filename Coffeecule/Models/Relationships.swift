//
//  Relationship.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 6/2/23.
//

import Foundation

struct Relationships: Equatable {
    let person: Person
    var name: String {
        person.name
    }
    var coffeesOwed: [Person:Int] = [:]
    var isPresent = false
    
    private static var all = [Relationships]()
    
    static public func populatePeople(with people: [Person]) -> [Relationships] {
        Self.all.removeAll()
        people.forEach {
            _ = updateRelationships(adding: $0)
        }
        return Self.all
    }
    
    static public func addPerson(_ person: Person) -> [Relationships] {
        return Self.updateRelationships(adding: person)
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
        Self.all = updatedRelationships
        return updatedRelationships
    }
    
    init(_ person: Person) {
        self.person = person
    }
}
