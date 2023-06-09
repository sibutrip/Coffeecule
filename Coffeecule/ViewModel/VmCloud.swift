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
        try await createZonesIfNeeded()
    }
    /// Creates the custom zone in use if needed.
    private func createZonesIfNeeded() async throws {
        try await Repository.database.modifyRecordZones(saving: [repository.currentZone], deleting: [])
    }
}





//    

//    
//    func removePerson(for deletingPerson: Person) async throws {
////        for item in ["buyerName","receiverName"] {
////            let predicate = NSPredicate(format: "%@ == %K", deletingPerson.name, item)
////            let query = CKQuery(recordType: Repository.shared.recordType, predicate: predicate)
////            let (results, _)  = try await Repository.shared.database.records(matching: query)
////            for (id, _) in results {
////                let _ = try await Repository.shared.database.deleteRecord(withID: id)
////            }
////        }
////        var updatedPeople = people.filter {
////            $0 != deletingPerson
////        }
////
////        updatedPeople = updatedPeople.map { person in
////            var updatedPerson = person
////            var coffeesOwed = person.coffeesOwed
////            coffeesOwed.removeValue(forKey: deletingPerson.name)
////            updatedPerson.coffeesOwed = coffeesOwed
////            return updatedPerson
////        }
////
////        self.people = updatedPeople
////        calculateBuyer()
////        ReadWrite.shared.writePeopleToDisk(people)
////        Task {
////            await ReadWrite.shared.writePeopleToCloud(people)
////        }
//    }
//    
//    
//    /// this only works as expected for Corycule
//    func backgroundUpdateCloud() async -> [Person]? {
//        let transactions = await ReadWrite.shared.readTransactionsFromCloud()
////        let people = await ReadWrite.shared.readPeopleFromCloud() ?? self.people
//        let people = self.people
//        /// need to include people who havent made transactions in [Person]
//        let updatedPeople = ReadWrite.shared.transactionsToPeople(transactions, people: people)
//        ReadWrite.shared.writePeopleToDisk(updatedPeople)
//        await ReadWrite.shared.writePeopleToCloud(updatedPeople)
//        print("in refresh, poeple are \(updatedPeople)")
//        return updatedPeople
//    }
//}
