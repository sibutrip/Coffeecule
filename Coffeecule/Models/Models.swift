//
//  Models.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/12/23.
//

import CloudKit

struct TransactionModel: Identifiable {
    let id: String
    var buyerName: String
    var receiverName: String
    var associatedRecord: CKRecord
    
    init?(record: CKRecord) {
        guard let buyerName = record["buyerName"] as? String,
              let receiverName = record["receiverName"] as? String else {
            return nil
        }

        self.id = record.recordID.recordName
        self.buyerName = buyerName
        self.receiverName = receiverName
        self.associatedRecord = record

    }
}

struct Contact: Identifiable {
    let id: String
    let name: String
    let phoneNumber: String
    let associatedRecord: CKRecord
}

extension Contact {
    /// Initializes a `Contact` object from a CloudKit record.
    /// - Parameter record: CloudKit record to pull values from.
    init?(record: CKRecord) {
        guard let name = record["name"] as? String,
              let phoneNumber = record["phoneNumber"] as? String else {
            return nil
        }

        self.id = record.recordID.recordName
        self.name = name
        self.phoneNumber = phoneNumber
        self.associatedRecord = record
    }
}

struct TransactionCache {
    var buyerName: String
    var receiverName: String
}

struct Relationship {
    var isPresent = false
    var coffeesOwed = 0
}

struct BuyerInfo: Codable {
    var isPresent = false
    var coffeesOwed = 0
    var relationships = [String: Int]()
}

struct JSONUtility {
    public func encodeCoffeeculeMembers(for members: [String]) -> Data {
        guard let encodedData = try? JSONEncoder().encode(members) else { return Data() }
        return encodedData
    }
    
    public func decodeCoffeeculeMembers(for members: Data) -> [String] {
        guard let decodedData = try? JSONDecoder().decode([String].self, from: members) else { return [String]() }
        return decodedData
    }
    
    public func encodeWeb(for relationshipWeb: [String:BuyerInfo]) -> Void {
        do {
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("relationshipWeb.json")
            
            try JSONEncoder()
                .encode(relationshipWeb)
                .write(to: fileURL)
        }
        catch {
            print("error writing data")
        }
    }
    
    public func decodeWeb() -> [String:BuyerInfo] {
        do {
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("relationshipWeb.json")
            
            let data = try Data(contentsOf: fileURL)
            var pastData = try JSONDecoder().decode([String:BuyerInfo].self, from: data)
//            for person in pastData {
//                pastData[person.key]?.isPresent = false
//            }
//            print(pastData)
            return pastData
        } catch {
            print("error reading web data")
            return [:]
        }
    }
    
    public func encodeCache(for transactions: [[String]]) -> Void {
        do {
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("cachedTransactions.json")
            
            try JSONEncoder()
                .encode(transactions)
                .write(to: fileURL)
        } catch {
            print("error writing data")
        }
    }
    
    public func decodeCache() -> [[String]] {
        do {
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("cachedTransactions.json")
            
            let data = try Data(contentsOf: fileURL)
            let cache = try JSONDecoder().decode([[String]].self, from: data)
            return cache
        } catch {
            print("error reading cache data")
            return []
        }
    }
    
}
