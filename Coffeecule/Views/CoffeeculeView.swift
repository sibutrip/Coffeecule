//
//  ContentView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/7/23.
//

import SwiftUI
import Charts


struct CoffeeculeView: View {
    @ObservedObject var vm: ViewModel
    @State var buyCoffee = false
    var body: some View {
        NavigationView {
            Form {
                whosGettingCoffee
                itsTimeForPersonToGetCoffee
                buyCoffeeButton
                relationshipWebChart
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
        }.onAppear {
            Task {
                try await vm.initialize()
            }
        }
    }
}

extension CoffeeculeView {
    var whosGettingCoffee: some View {
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
    }
    
    var itsTimeForPersonToGetCoffee: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("it's time for")
            Text("\(vm.currentBuyer)").font(.largeTitle)
                .animation(.default.speed(3.0), value: vm.currentBuyer)
            Text("to buy coffee")
            Spacer()
        }.frame(maxWidth: .infinity)
    }
    
    var buyCoffeeButton: some View {
        Section {
            Button("buy coffee") {
                buyCoffee = true
            }
            .disabled(vm.currentBuyer == "nobody")
            .alert("is \(vm.currentBuyer) buying coffee?", isPresented: $buyCoffee) {
                HStack {
                    Button("yes", role: .destructive) {
                        //                                vm.buyCoffee()
                    }
                    Button("no", role: .cancel) { }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    var relationshipWebChart: some View {
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
}

struct TestViewDummy: View {
    @StateObject var vm = ViewModel()
    @State var addedPeople = ["co","to"]
    var body: some View {
        OnboardingView(vm: vm)
    }
}

struct ContentView_Previews: PreviewProvider {
    @Binding var addedPeople: [String]
    static var previews: some View {
        TestViewDummy(vm: ViewModel())
    }
}


struct ContactsTestView: View {
    @StateObject var vm = ViewModel()
    @State var nameInput = ""
    @State var phoneInput = ""
    @State var isAddingContact = false
    
    //        let onAdd: ((String, String) async throws -> Void)? = addContact
    
    var body: some View {
        Button {
            Task {
                //                    try await vm.saveRecordToContainer()
                try await uploadTransaction(name: nameInput, phoneNumber: phoneInput)
            }
        } label: {
            Text("yooo")
            
        }
        .onAppear {
            Task {
                try await vm.initialize()
                //                try await vm.refresh()
            }
        }
        
    }
    private func uploadTransaction(name: String, phoneNumber: String) async throws {
        try await vm.uploadTransaction(buyerName: name, receiverName: phoneNumber)
        //        try await vm.refresh()
        isAddingContact = false
    }
    
}
