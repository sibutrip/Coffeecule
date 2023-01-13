//
//  OnboardingView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/13/23.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var vm: ViewModel
    @State var newPerson: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                addedPeople
                createCoffeeculeButton
            }
            .animation(.default, value: vm.addedPeople)
            .navigationTitle("who's in your coffeecule?")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
                vm.createNewCoffeecule(for: vm.addedPeople)
            }
        }
    }
}

extension OnboardingView {
    var createCoffeeculeButton: some View {
        Section {
            Text(vm.addedPeople.count < 2 ? "add people to continue" : "create coffeecule!")
                .foregroundColor(vm.addedPeople.count < 2 ? .gray : .blue)
                .background {
                    NavigationLink("") {
                        CoffeeculeView(vm: vm)
                            .navigationBarBackButtonHidden()
                    }.disabled(vm.addedPeople.count < 2)
                        .frame(maxWidth: .infinity)
                        .animation(.default.speed(1.75), value: vm.addedPeople.count)
                        .opacity(0.0)
                }.frame(maxWidth: .infinity)
        }
    }
    
    var addedPeople: some View {
        List {
            ForEach(vm.addedPeople, id: \.self) {
                Text($0)
            }.onDelete { IndexSet in
                vm.addedPeople.remove(atOffsets: IndexSet)
            }
            HStack {
                TextField("add a person...", text: $newPerson)
                Button {
                    vm.addedPeople.append(newPerson)
                    newPerson = ""
                } label: {
                    Image(systemName: "plus.circle")
                }
                .disabled(newPerson.isEmpty)
                .buttonStyle(PlainButtonStyle())
                .foregroundColor(.green)
            }
        }
    }
}
