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
    @Binding public var isSharing: Bool
    @Binding var isBuying: Bool
    
    var body: some View {
        Section("Who's getting coffee?") {
            List {
                ForEach(vm.relationships.indices, id: \.self) { index in
                    let relationship = vm.relationships[index]
                    let person = relationship.person
                    let displayedDebt = vm.displayedDebts[person]
                    let displayDebtColor: Color = {
                        guard let displayedDebt else { return Color.primary }
                        if displayedDebt < 0 {
                            return Color.red
                        } else if displayedDebt > 0 {
                            return Color.blue
                        } else {
                            return Color.primary
                        }
                    }()
                        Button {
                        vm.relationships[index].isPresent.toggle()
//                        vm.createDisplayedDebts()
//                        vm.calculateBuyer()
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
                            Spacer()
                            if let displayedDebt {
                                Text(displayedDebt.description)
                                    .foregroundStyle(displayDebtColor)
                            }
                        }
                        .if(vm.presentPeopleCount > 0) { view in
                            view.contextMenu {
                                Button("Buy Coffee") {
                                    var relationship = vm.relationships.first { $0.person == person }!
                                    var relationships = vm.relationships
                                    relationships = relationships.filter { $0 != relationship }
                                    relationship.isPresent = true
                                    relationships.append(relationship)
                                    relationships = relationships.sorted {$0.person < $1.person}
                                    vm.relationships = relationships
                                    vm.currentBuyer = person
                                    isBuying = true
                                }
                            }
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
    init(vm: ViewModel, share: Binding<CKShare?>, container: Binding<CKContainer?>, isSharing: Binding<Bool>, isBuying: Binding<Bool>) {
        self.vm = vm
        _share = share
        _container = container
        _isSharing = isSharing
        _isBuying = isBuying
    }
}


extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: @autoclosure () -> Bool, transform: (Self) -> Content) -> some View {
        if condition() {
            transform(self)
        } else {
            self
        }
    }
}
