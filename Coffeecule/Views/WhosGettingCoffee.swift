//
//  WhosGettingCoffee.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/24/23.
//

import Foundation
import SwiftUI

struct WhosGettingCoffee: View {
    @ObservedObject var vm: ViewModel
    @Environment(\.editMode) private var editMode
    @State private var deletingPerson = false
    @State private var personToDelete = Person(name: "nobody")
    @State private var deleteError = false
    @Binding var isSharing: Bool
    
    var body: some View {
        Section("Who's getting coffee?") {
            List {
                ForEach(vm.people.indices, id: \.self) { index in
                    let person = vm.people[index]
                    Button {
                        vm.people[index].isPresent.toggle()
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
                                .opacity(vm.people[index].isPresent ? 1.0 : 0.0)
                            Text("\(person.name)")
                                .foregroundColor(.black)
                        }
                    }
                }
                if self.editMode?.wrappedValue != .inactive {
                    Button {
                        Task {
                            await vm.shareCoffeecule()
                            isSharing = true
                        }
                    } label: {
                        HStack {
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                            Text("New bro")
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
