//
//  BuyerCalculations.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/14/23.
//

import Foundation

extension ViewModel {
    
    /// Calculate who the buyer should be based on who's present and their resepctive relative debts.
    public func calculateCurrentBuyer(for web: [String : BuyerInfo]) -> String {
        let presentPeople = calculatePresentPeople(for: relationshipWeb)
        let presentPeopleDebt = calculatePresentPeopleDebt(for: presentPeople)
        
        let sortedPeople = presentPeopleDebt.sorted { $0.1 > $1.1 }
        var currentBuyer = sortedPeople.first?.key ?? "nobody"
        if presentPeople.count < 2 {
            currentBuyer = "nobody"
        }
        
        return currentBuyer
    }
    
    
    // MARK: - PRIVATE
    
    /// Create array of people selected in the Coffeecule view.
    private func calculatePresentPeople(for web: [String : BuyerInfo]) -> [String] {
        var presentPeople = [String]()
        for person in web {
            if person.value.isPresent {
                presentPeople.append(person.key)
            }
        }
        return presentPeople
    }
    
    /// Create dictionary of present people and their resepctive relative debts.
    private func calculatePresentPeopleDebt(for people:[String]) -> [String:Int] {
        var presentPeopleDebt = [String:Int]()
        for giverName in people {
            var individualDebtCount = 0
            let relationshipWeb = relationshipWeb
            if let buyerInfo = relationshipWeb[giverName] {
                for receiverName in buyerInfo.relationships {
                    if people.contains(receiverName.key) {
                        individualDebtCount += receiverName.value
                    }
                }
            }
            
            presentPeopleDebt[giverName] = individualDebtCount
        }
        self.presentPeopleDebt = presentPeopleDebt
        return presentPeopleDebt
    }
    
}
