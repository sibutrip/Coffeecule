//
//  ContentView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/7/23.
//

import SwiftUI
import Charts
import CloudKit


struct MainView: View {
    @StateObject var vm = ViewModel()
    
    var body: some View {
        if vm.userHasCoffeeculeOnLaunch {
            ContentView(vm: vm)
        } else {
            TestView(vm: vm)
        }
    }
}

struct TestView: View {
    @ObservedObject var vm: ViewModel
    @State var newPerson: String = ""
    
    var body: some View {
        NavigationView {
            Form {
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

                Section {
                    Text(vm.addedPeople.count < 2 ? "add people to continue" : "create coffeecule!")
                        .foregroundColor(vm.addedPeople.count < 2 ? .gray : .blue)
                        .background {
                            NavigationLink("") {
                                ContentView(vm: vm)
                                    .navigationBarBackButtonHidden()
                            }.disabled(vm.addedPeople.count < 2)
                                .frame(maxWidth: .infinity)
                                .animation(.default.speed(1.75), value: vm.addedPeople.count)
                                .opacity(0.0)
                        }.frame(maxWidth: .infinity)
                }
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

struct ContentView: View {
    @ObservedObject var vm: ViewModel
    @State var buyCoffee = false
    var body: some View {
        NavigationView {
            Form {
                Section("who's getting coffee?") {
                    List((vm.relationshipWeb?.keys.sorted())!, id: \.self) { name in
                        Button {
                            
                            vm.relationshipWeb![name]?.isPresent.toggle()
                            vm.calculatePresentPeople()
                            vm.calculateCurrentBuyer()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                    .opacity(vm.relationshipWeb![name]?.isPresent ?? false ? 1.0 : 0.0)
                                Text("\(name)")
                                    .foregroundColor(.black)
                            }
                        }
                    }
                }
                VStack(alignment: .center) {
                    Spacer()
                    Text("it's time for")
                    Text("\(vm.currentBuyer)").font(.largeTitle)
                        .animation(.default.speed(3.0), value: vm.currentBuyer)
                    Text("to buy coffee")
                    Spacer()
                }.frame(maxWidth: .infinity)
                Section {
                    Button("buy coffee") {
                        buyCoffee = true
                    }
                    .disabled(vm.currentBuyer == "nobody")
                    .alert("is \(vm.currentBuyer) buying coffee?", isPresented: $buyCoffee) {
                        HStack {
                            Button("yes", role: .destructive) {
                                vm.buyCoffee()
                            }
                            Button("no", role: .cancel) { }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                VStack {
                    Chart(vm.presentPeopleDebt.keys.sorted(), id: \.self) {
                        BarMark(
                            x: .value("person", $0),
                            y: .value("cups bought", vm.presentPeopleDebt[$0] ?? 0)
                        )
                    }
                    
                }
                .frame(height: 100)
                .animation(.default, value: vm.presentPeopleDebt)
            }
            .navigationTitle("Coffeecule")
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.checkiCloudStatus()
                    } label: {
                        Text("\(vm.cachedTransactions.count)")
                            .padding()
                            .background {
                                Circle().foregroundColor(.red)
                            }
                    }
                }
            }
        }
    }
    
}

struct TestViewDummy: View {
    @StateObject var vm = ViewModel()
    @State var addedPeople = ["co","to"]
    var body: some View {
        TestView(vm: vm)
    }
}

struct ContentView_Previews: PreviewProvider {
    @Binding var addedPeople: [String]
    static var previews: some View {
        TestViewDummy(vm: ViewModel())
    }
}
