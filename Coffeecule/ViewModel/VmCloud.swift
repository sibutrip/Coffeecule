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
        print("initializing")
        do {
            try await createZonesIfNeeded()
            print("zones created")
        } catch {
            self.state = .error
        }
    }
    
    /// Creates the custom zone in use if needed.
    private func createZonesIfNeeded() async throws {
        if UserDefaults.standard.bool(forKey: "areZonesCreated") {
            print("zones already made")
            return
        }
        
        let id = CKRecord.ID(zoneID: RecordZones.Transactions().zoneID)
        let rootRecord = CKRecord(recordType: "CoffeeculeRootTest", recordID: id)
        let share = CKShare(rootRecord: rootRecord)
        Repository.shared.ckShare = share
        Repository.shared.rootRecord = rootRecord
        
        do {
            print(try await Repository.shared.database.modifyRecordZones(saving: [RecordZones.Transactions(), RecordZones.People()], deleting: []))
            print("zone creation success??")
            UserDefaults.standard.set(true, forKey: "areZonesCreated")
            
            
            do {
                let (saveResults,_) = try await Repository.shared.database.modifyRecords(saving: [share,rootRecord], deleting: [])
            } catch {
                print("could not upload share to database")
            }
            
            
        } catch {
            print("ERROR: Failed to create custom zone: \(error.localizedDescription)")
            throw error
        }
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
        
        self.people = updatedPeople
        calculateBuyer()
        ReadWrite.shared.writePeopleToDisk(people)
        Task {
            await ReadWrite.shared.writePeopleToCloud(people)
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
