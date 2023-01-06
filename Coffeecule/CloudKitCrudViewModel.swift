//
//  CloudKitCrudViewModel.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/8/23.
//

import SwiftUI
import CloudKit

struct FruitModel: Hashable {
    var name: String
    var record: CKRecord
}

class CloudKitCrudViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var fruits: [FruitModel] = []
    
    init() {
        fetchItems()
    }
    
    func addButtonPressed() {
        guard !text.isEmpty else { return }
        addItem(name: text)
    }
    
    private func addItem(name: String) {
        let newFruit = CKRecord(recordType: "Fruits")
        newFruit["name"] = name
        saveItem(record: newFruit)
    }
    
    private func saveItem(record: CKRecord) {
        CKContainer.default().publicCloudDatabase.save(record) { returnedRecord, returnedError in
//            print("Record: \(returnedRecord)")
//            print("Error: \(returnedError)")
        }
        DispatchQueue.main.async {
            self.text = ""
            self.fetchItems()
        }
    }
    func fetchItems() {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: "Fruits", predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        var returnedItems: [FruitModel] = []
        
        queryOperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                guard let name = record["name"] as? String else { return }
                returnedItems.append(FruitModel(name: name, record: record))
//                print("successfully read record")
            case .failure(let error):
                break
//                print("Error recordMatchedBlock: \(error)")
            }
        }
        
        queryOperation.queryResultBlock = { returnedResult in
//            print("RETURNED queryResultBlock: \(returnedResult)")
            DispatchQueue.main.async {
                self.fruits = returnedItems
            }
//            print(self.fruits)
        }
        addOperation(operation: queryOperation)
    }
    
    func addOperation(operation: CKQueryOperation) {
        CKContainer.default().publicCloudDatabase.add(operation )
    }
    
    func updateItem(fruit: FruitModel) {
        let record = fruit.record
        record["name"] = "New Name!!!"
        saveItem(record: record)
    }
}

struct CloudKitCrudView: View {
    @StateObject private var vm = CloudKitCrudViewModel()
    var body: some View {
        NavigationView {
            VStack {
                header
                textField
                addButton
                
                List(vm.fruits, id: \.self) { fruit in
                    Text(fruit.name)
                        .onTapGesture {
                            vm.updateItem(fruit: fruit)
                        }
                    
                }.listStyle(PlainListStyle())
            }
            .padding()
            .toolbar(.hidden, for: .automatic)
        }
    }
}

extension CloudKitCrudView {
    private var header: some View {
        Text("CloudKit CRUD ☁️☁️☁️")
            .font(.headline)
            .underline()
    }
    private var textField: some View {
        TextField("Add something here...", text: $vm.text)
            .frame(height: 55)
            .padding(.leading)
            .background(Color.gray.opacity(0.4))
            .cornerRadius(10)
    }
    private var addButton: some View {
        Button {
            vm.addButtonPressed()
        } label: {
            Text("add")
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 55)
                .frame(maxWidth: .infinity)
                .background(Color.pink)
                .cornerRadius(10)
        }
    }
}

struct CloudKitCrudView_Previews: PreviewProvider {
    static var previews: some View {
        CloudKitCrudView()
    }
}

