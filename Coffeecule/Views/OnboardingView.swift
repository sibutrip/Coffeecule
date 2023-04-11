////
////  OnboardingView.swift
////  CoffeeculeTest
////
////  Created by Cory Tripathy on 2/6/23.
////
//
//import Foundation
//import SwiftUI
//
//struct OnboardingView: View {
//    @ObservedObject var vm: ViewModel
//    @State var newPerson: String = ""
//    @State var addedPeople: [String] = []
//    @State var duplicatePersonAlert = false
//    
//    var body: some View {
//        NavigationView {
//            Form {
//                listOfMembers
//                createCoffeeculeButton
//            }
//            .animation(.default, value: addedPeople)
//            .navigationTitle("who's in your coffeecule?")
//            .navigationBarTitleDisplayMode(.inline)
//            .onAppear {
//                addedPeople.removeAll()
//            }.alert("\(newPerson) is already in your Coffeecule, try changing their name.", isPresented: $duplicatePersonAlert) {
//                Button("Okay", role: .cancel) {
//                    newPerson.removeAll()
//                }
//            }
//        }
//    }
//}
//
//extension OnboardingView {
//    
//    var listOfMembers: some View {
//        List {
//            ForEach(addedPeople, id: \.self) {
//                Text($0)
//            }.onDelete { IndexSet in
//                addedPeople.remove(atOffsets: IndexSet)
//            }
//            HStack {
//                TextField("add a person...", text: $newPerson)
//                Button {
//                    self.newPerson = newPerson.capitalized
//                    if addedPeople.contains(newPerson) {
//                        duplicatePersonAlert = true
//                        return
//                    }
//                    addedPeople.append(newPerson)
//                    self.newPerson = ""
//                } label: {
//                    Image(systemName: "plus.circle")
//                }
//                .disabled(newPerson.isEmpty)
//                .buttonStyle(PlainButtonStyle())
//                .foregroundColor(.green)
//            }
//        }
//    }
//    
//    var createCoffeeculeButton: some View {
//        Section {
//            Text(addedPeople.count < 2 ? "add people to continue" : "create coffeecule!")
//                .foregroundColor(addedPeople.count < 2 ? .gray : .blue)
//                .background {
//                    Button("make cule") {
//                        var peopleToAdd = addedPeople
//                        peopleToAdd.append(newPerson)
//                        vm.createNewCoffeecule(for: addedPeople)
//                        vm.calculateBuyer()
//                        ReadWrite.shared.writePeopleToDisk(vm.people)
//                        Task {
//                            await ReadWrite.shared.writePeopleToCloud(vm.people)
//                        }
//                    }
//                    .disabled(addedPeople.count < 2 || (addedPeople.count < 1 && newPerson.isEmpty))
//                    .frame(maxWidth: .infinity)
//                    .animation(.default.speed(1.75), value: addedPeople)
//                    .opacity(0.0)
//                }
//                .frame(maxWidth: .infinity)
//        }
//    }
//}
