//
//  WhosGettingCoffee.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/24/23.
//

import Foundation
import SwiftUI
import CloudKit

struct WhosGettingCoffee: View {
    @ObservedObject var vm: ViewModel
    @Environment(\.editMode) private var editMode
    @State private var deletingPerson = false
    @State private var personToDelete = Person()
    @State private var deleteError = false
    @Binding var share: CKShare?
    @Binding var container: CKContainer?
    @Binding var isSharing: Bool
    
    var body: some View {
        Section("Who's getting coffee?") {
            List {
                ForEach(vm.relationships.indices, id: \.self) { index in
                    let relationship = vm.relationships[index]
                    let person = relationship.person
                    Button {
                        vm.relationships[index].isPresent.toggle()
                        vm.createDisplayedDebts()
                        vm.calculateBuyer()
                    } label: {
                        HStack {
                            if self.editMode?.wrappedValue != .inactive {
                                Button {
                                    deletingPerson = true
                                    personToDelete = person
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.title3)
                                }
                            }
                            Image(systemName: "checkmark")
                                .opacity(vm.relationships[index].isPresent ? 1.0 : 0.0)
                            Text("\(person.name)")
                                .foregroundColor(Color.primary)
                        }
                    }
                }
                if self.editMode?.wrappedValue != .inactive || vm.relationships.count == 0 {
                    Button {
                        Task {
                            try await vm.shareCoffeecule()
                            if let share = await vm.repository.rootShare {
                                self.share = share
                                self.container = Repository.container
                                isSharing = true
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                            Text("Add New Person")
                        }
                    }.disabled(vm.state == .loading)
                }
            }
            .alert("Deleting is not available yet", isPresented: $deletingPerson) {
                HStack {
                    Button("No", role: .cancel) { deletingPerson = false }
//                    Button("Yes", role: .destructive) {
//                        vm.people.removeAll {
//                            $0 == personToDelete
//                        }
//                        Task {
//                            do {
//                                try await vm.removePerson(for: personToDelete)
//                            } catch {
//                                deleteError = true
//                            }
//                        }
//                    }
                }
            }
            .alert("Could not delete user, try again", isPresented: $deleteError) {
                Button("Okay") {
                    deleteError = false
                }
            }
        }
    }
}
