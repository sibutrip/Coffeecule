//
//  WebCalculations.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/23/23.
//

import Foundation

extension ViewModel {
    
    enum PopulateWebError: Error {
        case fail(String)
    }
    
    func populateWebFromCloud() async throws -> [String:BuyerInfo] {
        let transactionsTask = Task { () -> [String:BuyerInfo] in
            let populatedTransactions = try await fetchTransactions(scope: .private, in: [recordZone])
            return try convertTransactionsToWeb(for: populatedTransactions)
        }
        let transactions = await transactionsTask.result
        return try transactions.get()
    }
    
    func generateRelationshipWeb(for people: [String]) -> [String:BuyerInfo] {
        /// creates empty web template
        var relationshipWeb = [String:BuyerInfo]()
        for buyer in people {
            var buyerInfo = BuyerInfo()
            for receiver in people {
                if receiver != buyer {
                    buyerInfo.relationships[receiver] = 0
                }
            }
            relationshipWeb[buyer] = buyerInfo
        }
        return relationshipWeb
    }
    
    func convertTransactionsToWeb(for transactions: [TransactionModel]) throws -> [String:BuyerInfo]{
        var relationshipWeb = generateRelationshipWeb(for: coffeeculeMembers)
        for transaction in transactions {
            //                relationshipWeb[transaction.buyerName]?.relationships[transaction.receiverName]! -= 1
            //                relationshipWeb[transaction.receiverName]?.relationships[transaction.buyerName]! += 1
            guard var buyerInfo = relationshipWeb[transaction.buyerName] else {
                throw PopulateWebError.fail("\(transaction.buyerName) not found")
            }
            guard var debt = buyerInfo.relationships[transaction.receiverName] else {
                throw PopulateWebError.fail("receiver not found")
            }
            debt -= 1
            buyerInfo.relationships[transaction.receiverName] = debt
            relationshipWeb.updateValue(buyerInfo, forKey: transaction.buyerName)
            
            guard var buyerInfo = relationshipWeb[transaction.receiverName] else {
                throw PopulateWebError.fail("\(transaction.buyerName) not found")
            }
            guard var debt = buyerInfo.relationships[transaction.buyerName] else {
                throw PopulateWebError.fail("receiver not found")
            }
            debt += 1
            buyerInfo.relationships[transaction.buyerName] = debt
            relationshipWeb.updateValue(buyerInfo, forKey: transaction.receiverName)
        }
        return relationshipWeb
    }
}
