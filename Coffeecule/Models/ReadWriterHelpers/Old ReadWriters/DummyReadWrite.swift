////
////  DummyReadWrite.swift
////  CoffeeculeTest
////
////  Created by Cory Tripathy on 2/3/23.
////
//
//import Foundation
//
//struct DummyReadWriter: ReadWritable {
//    func readTransactions(existingPeople: [Person]?) -> [Person]  {
//        let names = ["cory","tom","zoe","tariq","ty","kevin"]
//        var people = [Person]()
//        for buyer in names {
//            var newPerson = Person(name: buyer)
//            for receiver in names {
//                if receiver != buyer {
//                    newPerson.coffeesOwed[receiver] = 0
//                }
//            }
//            people.append(newPerson)
//        }
//        return people
//    }
//    func writeTransactions(from transactions: [CachedTransaction]) -> [CachedTransaction]?{
//        do {
//            try JSONEncoder()
//                .encode(transactions)
//                .write(to: Repository.shared.dummyUrl)
//        } catch {
//            print("couldn't write to cachedDummyTransactions.json")
//        }
//        return nil
//    }
//    
//    func writePeopleToDisk(_ people: [Person]) {
//        do {
//            try JSONEncoder()
//                .encode(people)
//                .write(to: Repository.shared.dummyPeopleUrl)
//        } catch {
//            print("couldnt write people to disk")
//        }
//    }
//    
//    func readPeopleFromDisk() -> [Person] {
//        do {
//            let encodedPeople = try Data(contentsOf: Repository.shared.dummyPeopleUrl)
//            let decodedpeople = try JSONDecoder().decode([Person].self, from: encodedPeople)
//            return decodedpeople
//        } catch {
//            print("error reading cachedTransactions.json data")
//            return [Person]()
//        }
//    }
//    
//    static let shared = Self()
//}
