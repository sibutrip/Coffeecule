//
//  Relationship.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 6/2/23.
//

import Foundation

struct Relationship: Equatable {
    let person: Person
    var name: String {
        person.name
    }
    
    var coffeesOwed: [Person:Int] = [:]
    var isPresent = false
    
    init(_ person: Person) {
        self.person = person
    }
}

class RelationshipService {
    public func populate(with people: [Person]) -> [Relationship] {
        var relationships = [Relationship]()
        people.forEach { person in
            relationships = add(person, to: relationships)
        }
        return relationships
    }
    
//    public func populate(with people: [Person], and transactions: [Transaction]) -> [Relationship] {
//        //TODO: functions to populate with transactions
//        return []
//    }
    
    public func add(_ person: Person, to relationships: [Relationship]) -> [Relationship] {
        var updatedRelationships = [Relationship]()
        var newRelationship = Relationship(person)
        for var currentRelationship in relationships {
            newRelationship.coffeesOwed[currentRelationship.person] = 0
            currentRelationship.coffeesOwed[person] = 0
            updatedRelationships.append(currentRelationship)
        }
        updatedRelationships.append(newRelationship)
        return updatedRelationships
    }
    
    public func add(transactions: [Transaction], to people: [Person]) {}
}
