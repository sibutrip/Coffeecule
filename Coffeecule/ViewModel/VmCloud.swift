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
    func initialize() async {
        do {
            try await createZonesIfNeeded()
        } catch {
            state = .error
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
    //    public func refreshTransactions() async {
    //
    //        // key: name, value: isPresent
    //        var cachedPeopleStatus = [String:Bool]()
    //        for person in self.people {
    //            cachedPeopleStatus[person.name] = person.isPresent
    //        }
    //        let transactions = await ReadWrite.shared.readTransactionsFromCloud()
    //        var newPeople = ReadWrite.shared.transactionsToPeople(transactions, people: people)
    //        for index in newPeople.sorted().indices {
    //            if let cachedPersonStatus = cachedPeopleStatus[newPeople[index].name] {
    //                newPeople[index].isPresent = cachedPersonStatus
    //            }
    //        }
    //        self.people = newPeople
    //    }
    
    func removePerson(for deletingPerson: Person) async throws {
        for item in ["buyerName","receiverName"] {
            let predicate = NSPredicate(format: "%@ == %K", deletingPerson.name, item)
            let query = CKQuery(recordType: Repository.shared.recordType, predicate: predicate)
            let (results, _)  = try await Repository.shared.database.records(matching: query)
            for (id, _) in results {
                let _ = try await Repository.shared.database.deleteRecord(withID: id)
            }
        }
        //        let transactions = await ReadWrite.shared.readTransactionsFromCloud()
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
        //        let people = ReadWrite.shared.transactionsToPeople(transactions, people: updatedPeople)
        self.people = updatedPeople
        calculateBuyer()
        ReadWrite.shared.writePeopleToDisk(people)
        Task {
            //            await self.updatePeople(people)
            await ReadWrite.shared.writePeopleToCloud(people)
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
    
    func backgroundUpdateCloud() async -> [Person]? {
        let transactions = await ReadWrite.shared.readTransactionsFromCloud()
        let people = await ReadWrite.shared.readPeopleFromCloud() ?? self.people
        print("in refresh, poeple are \(people)")
        /// need to include people who havent made transactions in [Person]
        let updatedPeople = ReadWrite.shared.transactionsToPeople(transactions, people: people)
        ReadWrite.shared.writePeopleToDisk(updatedPeople)
        await ReadWrite.shared.writePeopleToCloud(updatedPeople)
        return updatedPeople
    }
}
