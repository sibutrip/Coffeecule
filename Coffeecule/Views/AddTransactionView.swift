//
//  AddTransactionView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/24/23.
//

import Foundation
import SwiftUI

struct AddTransactionView: View {
    @Binding var processingTransaction: Bool
    @ObservedObject var vm: ViewModel
    var allPeople: [Person] = []
    @State var buyer: Person
//    @State var processingTransaction = false
    @State var receivers: Set<Person> = []
    @Environment(\.dismiss) var dismiss
    var peopleRemovingBuyer: [Person] {
        allPeople
            .filter { $0 != buyer }
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
                            buyer = person
                        } label: {
                            Text("\(person.name)")
                                .foregroundColor(Color.primary)
                        }
                    }
                }
                Section {
                    Button("Buy Coffee") {
                        processingTransaction = true
                        Task {
                            await vm.buyCoffee(buyer: buyer, receivers: vm.presentPeople)
//                            vm.createDisplayedDebts()
//                            vm.calculateBuyer()
                            processingTransaction = false
                        }
                        dismiss()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .onChange(of: buyer) { _ in
                receivers.removeAll()
            }
            .navigationTitle("Select Buyer")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    init(vm: ViewModel, processingTransaction: Binding<Bool>) {
        self.vm = vm
        allPeople = vm.relationships
            .filter {$0.isPresent}
            .map { $0.person }
        _buyer = .init(initialValue: vm.currentBuyer)
        _processingTransaction = processingTransaction
    }
}
