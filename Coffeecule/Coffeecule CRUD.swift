//
//  Coffeecule CRUD.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/8/23.
//

import CloudKit
import SwiftUI


extension ViewModel {
    
    func checkiCloudStatus() {
        CKContainer.default().accountStatus { returnedStatus, returnedError in
            CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] returnedStatus, returnedError in
                DispatchQueue.main.async {
                    guard let coffeeculeMembersData = self?.coffeeculeMembersData else { return }
                    let people = JSONUtility().decodeCoffeeculeMembers(for: coffeeculeMembersData)
                    self?.generateRelationshipWeb(for: people)
                    self?.cachedTransactions = JSONUtility().decodeCache()
                    if returnedStatus == .granted {
                        // iCLOUD IS ACTIVE
                        // upload transactions, fetch cache, populate web from cloud, save web to JSON
                        self?.uploadCachedTransactions()
                        self?.fetchItems()
                        if let web = self?.relationshipWeb {
                            JSONUtility().encodeWeb(for: web)
                            print("web encoded")
                        } else {print("web not encoded")}
                        print("from cloud!")
                    } else {
                        // iCLOUD IS INACTIVE
                        self?.populateRelationshipWeb(from: .Cache)
                        print("from cache!")
                    }
                }
            }
        }
    }
    
    private func uploadCachedTransactions() {
        var transactionsToUpload = cachedTransactions
        self.cachedTransactions.removeAll()
        while transactionsToUpload.count > 0 {
            if let poppedCachedTransaction = transactionsToUpload.popLast() {
                self.addItem(buyerName: poppedCachedTransaction[0], receiverName: poppedCachedTransaction[1])
                print("cached transaction \(poppedCachedTransaction) uploaded to cloud")
            }
        }
        print("yooo you deleted cached transactions: \(self.cachedTransactions)")
        JSONUtility().encodeCache(for: self.cachedTransactions)
        print("yooo you rewrote cached transactions: \(self.cachedTransactions)")
    }
    
    
    func addItem(buyerName: String, receiverName: String) {
        /// create a CK record
        let newTransaction = CKRecord(recordType: cloudContainer)
        newTransaction["buyerName"] = buyerName
        newTransaction["receiverName"] = receiverName
        saveItem(record: newTransaction)
    }
    
    
    private func saveItem(record: CKRecord) {
        /// save record to cloud
        CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, returnedError in
            if returnedError != nil {
                // add record to cache if unable to upload
                guard let cachedBuyerName = record["buyerName"] as? String else { return }
                guard let cachedReceiverName = record["receiverName"] as? String else { return }
                self.cachedTransactions.append([cachedBuyerName,cachedReceiverName])
                JSONUtility().encodeCache(for: self.cachedTransactions)
                print("transaction couldnt upload, cached Transactions are \(self.cachedTransactions)")
            } else if returnedRecord != nil {
                print("buyer: \(record["buyerName"]!) receiver: \(record["receiverName"]!) uploaded to cloud!")
            }
        }
        DispatchQueue.main.async { }
    }
    
    func fetchItems() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: cloudContainer, predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        queryOperation.qualityOfService = .userInteractive
        
        var returnedTransactions: [TransactionModel] = []
        
        queryOperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            //            print("fetched!")
            switch returnedResult {
            case .success(let record):
                guard let buyerName = record["buyerName"] as? String else { return }
                guard let receiverName = record["receiverName"] as? String else { return }
                returnedTransactions.append(TransactionModel(buyerName: buyerName, receiverName: receiverName, record: record))
            default:
                break
            }
        }
        
        queryOperation.queryResultBlock = { returnedResult in
            DispatchQueue.main.async {
                self.transactions = returnedTransactions
                self.populateRelationshipWeb(from: .Cloud)
                print("web after fetch is \(self.relationshipWeb)")
            }
        }
        addOperation(operation: queryOperation)
    }
    
    private func addOperation(operation: CKQueryOperation) {
        CKContainer.default().publicCloudDatabase.add(operation)
    }
    
    private func updateItem(recipient: String) {
        let record = CKRecord(recordType: cloudContainer)
        for person in presentPeople {
            record["buyerName"] = currentBuyer
            record["receiverName"] = person
            saveItem(record: record)
        }
    }
}

extension ViewModel {

    // MARK: - Error

    enum ViewModelError: Error {
        case invalidRemoteShare
    }

    // MARK: - State

    enum State {
        case loading
        case loaded(private: [Contact], shared: [Contact])
        case error(Error)
    }


    // MARK: - API

    /// Prepares container by creating custom zone if needed.
    func initialize() async throws {
        do {
            try await createZoneIfNeeded()
        } catch {
            state = .error(error)
            
        }
    }

    /// Fetches contacts from the remote databases and updates local state.
    func refresh() async throws {
        state = .loading
        do {
            let (privateContacts, sharedContacts) = try await fetchPrivateAndSharedContacts()
            state = .loaded(private: privateContacts, shared: sharedContacts)
        } catch {
            state = .error(error)
        }
    }

    /// Fetches both private and shared contacts in parallel.
    /// - Returns: A tuple containing separated private and shared contacts.
    func fetchPrivateAndSharedContacts() async throws -> (private: [Contact], shared: [Contact]) {
        // This will run each of these operations in parallel.
        async let privateContacts = fetchContacts(scope: .private, in: [recordZone])
        async let sharedContacts = fetchSharedContacts()

        return (private: try await privateContacts, shared: try await sharedContacts)
    }

    /// Adds a new Contact to the database.
    /// - Parameters:
    ///   - name: Name of the Contact.
    ///   - phoneNumber: Phone number of the contact.
    func addContact(name: String, phoneNumber: String) async throws {
        let id = CKRecord.ID(zoneID: recordZone.zoneID)
        let contactRecord = CKRecord(recordType: "SharedContact", recordID: id)
        contactRecord["name"] = name
        contactRecord["phoneNumber"] = phoneNumber

        do {
            try await database.save(contactRecord)
        } catch {
            debugPrint("ERROR: Failed to save new Contact: \(error)")
            throw error
        }
    }

    /// Fetches an existing `CKShare` on a Contact record, or creates a new one in preparation to share a Contact with another user.
    /// - Parameters:
    ///   - contact: Contact to share.
    ///   - completionHandler: Handler to process a `success` or `failure` result.
    func fetchOrCreateShare(contact: Contact) async throws -> (CKShare, CKContainer) {
        guard let existingShare = contact.associatedRecord.share else {
            let share = CKShare(rootRecord: contact.associatedRecord)
            share[CKShare.SystemFieldKey.title] = "Contact: \(contact.name)"
            _ = try await database.modifyRecords(saving: [contact.associatedRecord, share], deleting: [])
            return (share, container)
        }

        guard let share = try await database.record(for: existingShare.recordID) as? CKShare else {
            throw ViewModelError.invalidRemoteShare
        }

        return (share, container)
    }

    // MARK: - Private

    /// Fetches contacts for a given set of zones in a given database scope.
    /// - Parameters:
    ///   - scope: Database scope to fetch from.
    ///   - zones: Record zones to fetch contacts from.
    /// - Returns: Combined set of contacts across all given zones.
    private func fetchContacts(
        scope: CKDatabase.Scope,
        in zones: [CKRecordZone]
    ) async throws -> [Contact] {
        let database = container.database(with: scope)
        var allContacts: [Contact] = []

        // Inner function retrieving and converting all Contact records for a single zone.
        @Sendable func contactsInZone(_ zone: CKRecordZone) async throws -> [Contact] {
            var allContacts: [Contact] = []

            /// `recordZoneChanges` can return multiple consecutive changesets before completing, so
            /// we use a loop to process multiple results if needed, indicated by the `moreComing` flag.
            var awaitingChanges = true
            /// After each loop, if more changes are coming, they are retrieved by using the `changeToken` property.
            var nextChangeToken: CKServerChangeToken? = nil

            while awaitingChanges {
                let zoneChanges = try await database.recordZoneChanges(inZoneWith: zone.zoneID, since: nextChangeToken)
                let contacts = zoneChanges.modificationResultsByID.values
                    .compactMap { try? $0.get().record }
                    .compactMap { Contact(record: $0) }
                allContacts.append(contentsOf: contacts)

                awaitingChanges = zoneChanges.moreComing
                nextChangeToken = zoneChanges.changeToken
            }

            return allContacts
        }

        // Using this task group, fetch each zone's contacts in parallel.
        try await withThrowingTaskGroup(of: [Contact].self) { group in
            for zone in zones {
                group.addTask {
                    try await contactsInZone(zone)
                }
            }

            // As each result comes back, append it to a combined array to finally return.
            for try await contactsResult in group {
                allContacts.append(contentsOf: contactsResult)
            }
        }

        return allContacts
    }

    /// Fetches all shared Contacts from all available record zones.
    private func fetchSharedContacts() async throws -> [Contact] {
        let sharedZones = try await container.sharedCloudDatabase.allRecordZones()
        guard !sharedZones.isEmpty else {
            return []
        }

        return try await fetchContacts(scope: .shared, in: sharedZones)
    }

    /// Creates the custom zone in use if needed.
    private func createZoneIfNeeded() async throws {
        // Avoid the operation if this has already been done.
        guard !UserDefaults.standard.bool(forKey: "isZoneCreated") else {
            return
        }

        do {
            _ = try await database.modifyRecordZones(saving: [recordZone], deleting: [])
        } catch {
            print("ERROR: Failed to create custom zone: \(error.localizedDescription)")
            throw error
        }

        UserDefaults.standard.setValue(true, forKey: "isZoneCreated")
    }
}
