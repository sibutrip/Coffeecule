//
//  VMPeople.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/11/23.
//

import Foundation
import CloudKit

extension ViewModel {
    public func joinCoffeecule(name: String) async {
        let record = await personService.createParticipantRecord(for: name)
        self.allRecords.append(record)
        await personService.saveSharedRecord(record)
        self.people = personService.addPersonToCoffecule(name, to: self.people)
        print(self.people)
    }
    
    public func createCoffeecule(name: String) async {
        do {
            let record = try personService.createRootRecord(for: name)
            self.allRecords.append(record)
            await personService.savePrivateRecord(record)
        } catch {
            debugPrint(error.localizedDescription)
        }
    }
    
    public func shareCoffeecule() async {
        await personService.fetchOrCreateShare()
    }
    
    public func refreshData() async {
        var (people, transactions, share) = await personService.fetchRecords(scope: .shared)
        people.append(contentsOf: await personService.fetchPrivatePeople())
        self.allRecords.removeAll()
        self.allRecords = people
    }
}
