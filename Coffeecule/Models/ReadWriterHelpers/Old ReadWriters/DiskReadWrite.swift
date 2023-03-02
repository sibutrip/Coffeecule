////
////  DiskReadWrite.swift
////  CoffeeculeTest
////
////  Created by Cory Tripathy on 2/3/23.
////
//
//import Foundation
//
//
//
//
//struct DiskReadWriterOLD: ReadWritable {
//
//    
//    func readTransactions(existingPeople: [Person]? = nil) async -> [Person]  {
//            let transactions = decodeTransactions()
//            let people = transactionsToPeople(for: transactions, existingPeople: existingPeople)
//            return people
//    }
//    
//    func writeTransactions(from transactions: [CachedTransaction]) -> [CachedTransaction]? {
//        do {
//            try JSONEncoder()
//                .encode(transactions)
//                .write(to: Repository.shared.url)
//        } catch {
//            print("couldn't write to cachedTransactions.json")
//        }
//        
//        return nil
//    }
//    
//    func decodeTransactions() -> [CachedTransaction]  {
//        do {
//            let encodedTransactions = try Data(contentsOf: Repository.shared.url)
//            let decodedTransactions = try JSONDecoder().decode([CachedTransaction].self, from: encodedTransactions)
//            return decodedTransactions
//        } catch {
//            print("error reading cachedTransactions.json data")
//            return [CachedTransaction]()
//        }
//    }
//    
//    func writePeopleToDisk(_ people: [Person]) {
//        do {
//            try JSONEncoder()
//                .encode(people)
//                .write(to: Repository.shared.peopleUrl)
//        } catch {
//            print("couldnt write people to disk")
//        }
//    }
//    
//    func readPeopleFromDisk() -> [Person] {
//        do {
//            let encodedPeople = try Data(contentsOf: Repository.shared.peopleUrl)
//            let decodedpeople = try JSONDecoder().decode([Person].self, from: encodedPeople)
//            return decodedpeople
//        } catch {
//            print("error reading cachedTransactions.json data")
//            return [Person]()
//        }
//    }
//    static let shared = Self()
//}
