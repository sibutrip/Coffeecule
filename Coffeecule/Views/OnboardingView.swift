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
    @State var addedPeople: [String] = []
    
    var body: some View {
        NavigationView {
            Form {
                listOfMembers
                createCoffeeculeButton
            }
            .animation(.default, value: vm.addedPeople)
            .navigationTitle("who's in your coffeecule?")
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear {
            }
            .onAppear {
                addedPeople.removeAll()
            }
        }
    }
}

extension OnboardingView {
    
    var listOfMembers: some View {
        List {
            ForEach(addedPeople, id: \.self) {
                Text($0)
            }.onDelete { IndexSet in
                addedPeople.remove(atOffsets: IndexSet)
            }
            HStack {
                TextField("add a person...", text: $newPerson)
                Button {
                    addedPeople.append(newPerson)
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
    
    var createCoffeeculeButton: some View {
        Section {
            Text(addedPeople.count < 2 ? "add people to continue" : "create coffeecule!")
                .foregroundColor(addedPeople.count < 2 ? .gray : .blue)
                .background {
                    Button("make cule", action: {
                        var peopleToAdd = addedPeople
                        peopleToAdd.append(newPerson)
                        vm.coffeeculeMembers = peopleToAdd
                        print("addedfdf")
                    })
//                    NavigationLink("") {
//                        CoffeeculeView(vm: vm)
//                        .navigationBarBackButtonHidden()
//                    }
                    .disabled(addedPeople.count < 2)
                        .frame(maxWidth: .infinity)
                        .animation(.default.speed(1.75), value: addedPeople)
                        .opacity(0.0)
                }.frame(maxWidth: .infinity)
        }
    }
}
