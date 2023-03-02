//
//  VmCloud.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/21/23.
//

import Foundation
import CloudKit

extension ViewModel {
    
    /// Prepares container by creating custom zone if needed.
    func initialize() async throws {
        do {
            try await createZonesIfNeeded()
        } catch {
            state = .error(error)
        }
    }
    
    /// Creates the custom zone in use if needed.
    private func createZonesIfNeeded() async throws {
        if UserDefaults.standard.bool(forKey: "areZonesCreated") {
            return
        }
        
        do {
            print(try await Repository.shared.database.modifyRecordZones(saving: [RecordZones.Transactions(), RecordZones.People()], deleting: []))
            UserDefaults.standard.set(true, forKey: "areZonesCreated")
        } catch {
            print("ERROR: Failed to create custom zone: \(error.localizedDescription)")
            throw error
        }
    }
    
    
    
    
    /// Cache a person's present status.
    /// Populate people from cloud.
    /// Mark present people as present in the updated people.
    public func refreshTransactions() async {
        
        // key: name, value: isPresent
        var cachedPeopleStatus = [String:Bool]()
        for person in self.people {
            cachedPeopleStatus[person.name] = person.isPresent
        }
        let transactions = await ReadWrite.shared.readTransactionsFromCloud()
        var newPeople = ReadWrite.shared.transactionsToPeople(transactions, people: people)
        for index in newPeople.sorted().indices {
            if let cachedPersonStatus = cachedPeopleStatus[newPeople[index].name] {
                newPeople[index].isPresent = cachedPersonStatus
            }
        }
        self.people = newPeople
    }
    
    func removePerson(for deletingPerson: Person) async throws {
        for item in ["buyerName","receiverName"] {
            let predicate = NSPredicate(format: "%@ == %K", deletingPerson.name, item)
            let query = CKQuery(recordType: Repository.shared.recordType, predicate: predicate)
            let (results, _)  = try await Repository.shared.database.records(matching: query)
            for (id, _) in results {
                let _ = try await Repository.shared.database.deleteRecord(withID: id)
            }
        }
        let transactions = await ReadWrite.shared.readTransactionsFromCloud()
        var updatedPeople = people.filter {
            $0 != deletingPerson
        }
        
        updatedPeople = updatedPeople.map { person in
            var updatedPerson = person
            var coffeesOwed = person.coffeesOwed
            coffeesOwed.removeValue(forKey: deletingPerson.name)
            updatedPerson.coffeesOwed = coffeesOwed
            return updatedPerson
        }
    
        
        print(updatedPeople)
        let people = ReadWrite.shared.transactionsToPeople(transactions, people: updatedPeople)
        self.people = people
        calculateBuyer()
        ReadWrite.shared.writePeopleToDisk(people)
        Task {
//            await self.updatePeople(people)
            await ReadWrite.shared.writePeopleToCloud(people)
        }
    }
    
    func updatePeople(_ people: [Person]) async {
        do {
            let query = CKQuery(recordType: Repository.shared.recordType, predicate: NSPredicate(value: true))
            let (results, _)  = try await Repository.shared.database.records(matching: query, inZoneWith: RecordZones.People().zoneID, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
            for (_, result) in results {
                switch result {
                case .success(let result):
                    
                    let data = try JSONEncoder().encode(self.people)
                    result["people"] = NSData(data: data)
                    try await Repository.shared.database.save(result)
                    
                case .failure(_):
                    print("failed to fetch person record")
                }
            }
        } catch {
            print("failed to update person record")
        }
    }
    
    func deletePeople() async {
        do {
            let query = CKQuery(recordType: Repository.shared.recordType, predicate: NSPredicate(value: true))
            let (results, _)  = try await Repository.shared.database.records(matching: query, inZoneWith: RecordZones.People().zoneID, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults)
            for (id, _) in results {
                let _ = try await Repository.shared.database.deleteRecord(withID: id)
            }
        } catch {
            print("error delete people json")
        }
    }
}
