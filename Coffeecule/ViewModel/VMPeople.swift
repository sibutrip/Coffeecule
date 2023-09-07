//
//  VMPeople.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

extension ViewModel {
    
    public var presentPeopleCount: Int {
        return relationships.filter { $0.isPresent }.count
    }
    
    var presentPeople: Set<Person> {
        let people = relationships.filter { $0.isPresent }.map { $0.person }
        return Set(people)
    }
    
    public func createCoffeecule() async throws {
        self.state = .loading
        try await assignUserID()
        try await self.populateData()
        if await self.repository.rootShare != nil {
            state = .culeAlreadyExists
            return
        }
        if self.participantName.isEmpty {
            state = .nameFieldEmpty
            return
        }
        if self.relationships.contains(where: {
            $0.name == self.participantName
        }) {
            state = .nameAlreadyExists
            return
        }
        if await repository.rootShare != nil {
            state = .culeAlreadyExists
            return
        }
        guard let userID = userID else {
            state = .noPermission
            return
        }
        let person = await Person(name: self.participantName, participantType: .root, userID: userID, in: repository)
        self.relationships = relationshipService.add(person, to: relationships)
        self.hasShare = try await personService.createRootShare()
        try await personService.saveRecord(person.associatedRecord, participantType: .root)
        
        self.state = .loaded
//        self.createDisplayedDebts()
//        self.calculateBuyer()
        self.state = .loaded
    }
    
    private func ownsCoffeecule() async -> Bool {
        let returnedRecords: [CKRecord]
        do {
            try await assignUserID()
            let predicate = NSPredicate(value: true)
            let query = CKQuery(recordType: "rootRecord", predicate: predicate)
            let privateZone = await repository.privateZone
            let (results, _) = try await Repository.container.privateCloudDatabase.records(matching: query, inZoneWith: privateZone.zoneID,desiredKeys: nil, resultsLimit: 10)
            returnedRecords = results.compactMap { result in
                switch result.1 {
                case .success(let record):
                    return record
                case .failure(_):
                    return nil
                }
            }
        } catch {
            returnedRecords = []
            print(CloudError.couldNotRetrieveRecords.errorDescription ?? "")
        }
        if returnedRecords.count > 1 {
            print(PersonError.multipleCoffeeculesExist.errorDescription ?? "")
        }
        if returnedRecords.count == 0 { return false }
        let returnedRecordName = returnedRecords[0]["userID"] as? String
        return userID == returnedRecordName
    }
    
    public func joinCoffeecule() async throws {
        self.state = .loading
        try await self.populateData()
        if await repository.rootShare == nil {
            state = .noShareFound
            return
        }
        if self.participantName.isEmpty {
            state = .nameFieldEmpty
            return
        }
        if self.relationships.contains(where: {
            $0.name == self.participantName
        }) {
            state = .nameAlreadyExists
            return
        }
        guard let userID = userID else {
            state = .noPermission
            return
        }
        let person = await Person(name: self.participantName, participantType: .participant, userID: userID, in: repository)
        try await personService.saveRecord(person.associatedRecord, participantType: .participant)
        self.relationships = relationshipService.add(person, to: relationships)
        self.state = .loaded
        self.hasShare = true
    }
    
    public func refreshData() async {
        do {
            try await populateData()
        } catch { }
    }
    
    public func loadData() async throws {
        do {
            self.state = .loading
            try await assignUserID()
            try await populateData()
        } catch {
            print(error.localizedDescription)
        }
        self.state = .loaded
    }
    
    public func shareCoffeecule() async throws {
        self.hasShare = try await personService.fetchOrCreateShare()
    }
    
    private func populateData() async throws {
        if let shareMetadata = Repository.shareMetaData {
            if await ownsCoffeecule() {
                self.personError = .alreadyOwnsCoffeecule
                personRecordCreationDidFail = true
                Repository.shareMetaData = nil
            } else {
                try await repository.acceptSharedContainer(with: shareMetadata)
                Repository.shareMetaData = nil
            }
        }
        let (fetchedPeople, transactions, hasShare) = await personService.fetchRecords()
        let presentPeople = relationships
            .filter { $0.isPresent }
            .map { $0.name }
        
        var relationships = try relationshipService.add(transactions: transactions, to: fetchedPeople)
        relationships = relationships.map { relationship in
            var relationship = relationship
            if presentPeople.contains(where: { $0 == relationship.name }) {
                relationship.isPresent = true
            }
            return relationship
        }
        self.relationships = relationships
        
        print("received \(transactions.count) transactions")
        print("received \(fetchedPeople.count) people")
        print("found a share: \(hasShare ? "yes" : "no")")
        self.hasShare = hasShare
        
        // determine if user is root user or shared user
        let rootRecordName = await repository.rootRecord?.recordID.recordName
        if relationships.contains(where: { relationship in
            relationship.person.userID == self.userID
        }) && self.userID == rootRecordName {
            participantType = .root
        } else {
            participantType = .participant
        }
    }
    
    public func shortenName(_ nameComponents: PersonNameComponents?) -> String {
        guard let nameComponents = nameComponents else { return "" }
        if let name = nameComponents.givenName, var famName = nameComponents.familyName {
            return "\(name) \(famName.removeFirst())."
        } else {
            return ""
        }
    }
    
    public func deleteCoffeecule() async throws {
        try await personService.deleteAllTransactions()
        try await personService.deleteAllUsers(relationships)
        try await personService.deleteShare()
        self.hasShare = false
        self.relationships.removeAll()
        await self.repository.share(nil)
        await self.repository.rootRecord(nil)
    }
}
