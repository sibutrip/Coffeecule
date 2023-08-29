//
//  AddTransactionView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/24/23.
//

import Foundation
import SwiftUI

struct AddTransactionView: View {
    @ObservedObject var vm: ViewModel
    var allPeople: [Person] = []
    @State var buyer: Person
    //    @State var receiver: Person = Person()
    @State var processingTransaction = false
    @State var receivers: Set<Person> = []
    @Environment(\.dismiss) var dismiss
    var peopleRemovingBuyer: [Person] {
        vm.relationships.map { $0.person } .filter { $0 != buyer }
    }
    var body: some View {
        NavigationView {
            List {
                Picker("Buyer", selection: $buyer) {
                    ForEach(allPeople) { person in
                        Text(person.name).tag(person)
                    }
                }
                Section("Receivers") {
                    ForEach(peopleRemovingBuyer) { person in
                        Button {
                            let (alreadySelected,_) = receivers.insert(person)
                            if !alreadySelected {
                                receivers.remove(person)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                    .opacity(receivers.contains { $0 == person} ? 1 : 0)
                                Text("\(person.name)")
                                    .foregroundColor(Color.primary)
                            }
                        }
                    }
                }
                Section {
                    Button("Buy Coffee") {
                        processingTransaction = true
                        Task {
                            await vm.buyCoffee(buyer: buyer, receivers: receivers)
                            vm.createDisplayedDebts()
                            vm.calculateBuyer()
                            processingTransaction = false
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(receivers.isEmpty)
                }
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    init(vm: ViewModel) {
        self.vm = vm
        allPeople = vm.relationships.map { $0.person }
        _buyer = .init(initialValue: vm.relationships.first?.person ?? Person())
    }
}
