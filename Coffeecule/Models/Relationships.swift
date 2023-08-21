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
    enum RelationshipError: Error {
        case noBuyer, noReceiver
    }
    /// create relationships from people with no transactions
    public func populate(with people: [Person]) -> [Relationship] {
        var relationships = [Relationship]()
        people.forEach { person in
            relationships = add(person, to: relationships)
        }
        return relationships
    }
    
    /// Add a new person to existing relationships
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
    
    /// add transactions to existing people.
    public func add(transactions: [Transaction], to people: [Person]) throws -> [Relationship] {
        var relationships = people.map { Relationship($0) }
        try transactions.forEach { transaction in
            let buyerName = transaction.buyerName
            let receiverName = transaction.receiverName
            guard var buyer = relationships.first( where: { $0.name == buyerName }) else {
                throw RelationshipError.noBuyer
            }
            guard let receiver = people.first(where: { $0.name == receiverName}) else {
                throw RelationshipError.noReceiver
            }
            var coffeesOwed = buyer.coffeesOwed[receiver] ?? 0
            coffeesOwed += 1
            buyer.coffeesOwed[receiver] = coffeesOwed
            
            // remove the old person, add the new one
            relationships.removeAll { $0.person == buyer.person }
            relationships.append(buyer)
        }
        return relationships
    }
}
