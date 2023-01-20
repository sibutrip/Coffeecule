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
    var body: some View {
        NavigationView {
            Form {
                whosGettingCoffee
                itsTimeForPersonToGetCoffee
                buyCoffeeButton
                relationshipWebChart
            }
            .scrollDisabled(true)
            .navigationTitle("Coffeecule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    settingsToolbar
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    selectAllToolbar
                }
            }
        }
    }
}

extension CoffeeculeView {
    
    // MARK: - State
    
    var iCloudState: Bool {
        switch vm.state {
        case .loaded:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Computed Views
    
    var whosGettingCoffee: some View {
        Section("who's getting coffee?") {
            if iCloudState {
                List {
                    ForEach(vm.coffeeculeMembers, id: \.self) { name in
                        Button {
                            vm.relationshipWeb[name]?.isPresent.toggle()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                    .opacity(vm.relationshipWeb[name]?.isPresent ?? false ? 1.0 : 0.0)
                                Text("\(name)")
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .onDelete { person in
                        vm.coffeeculeMembers.remove(atOffsets: person)
                        refreshTransactions()
                    }
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
    
    var itsTimeForPersonToGetCoffee: some View {
        Section {
            VStack(alignment: .center) {
                Spacer()
                Text("it's time for")
                Text("\(vm.currentBuyer)").font(.largeTitle)
                    .animation(.default.speed(3.0), value: vm.currentBuyer)
                Text("to buy coffee")
                Spacer()
            }.frame(maxWidth: .infinity)
        }
    }
    
    var buyCoffeeButton: some View {
        Section {
            Button("buy coffee") {
                Task {
                    try await uploadTransactions()
                    refreshTransactions()
                }
            }
            .disabled(vm.currentBuyer == "nobody" )
        }
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
    
    // MARK: - Toolbars
    
    var settingsToolbar: some View {
        EditButton()
    }
#warning("change from offline to online on successful fetch")
    
    
    var selectAllToolbar: some View {
        Button {
            for person in vm.relationshipWeb {
                vm.relationshipWeb[person.key]?.isPresent = true
            }
        } label: {
            Text("Select All")
        }
    }
    
    
    // MARK: - View Methods
    
    func uploadTransactions() async throws {
        let buyerName = vm.currentBuyer
        for receiverName in vm.relationshipWeb.keys {
            if let isPresent = vm.relationshipWeb[receiverName]?.isPresent {
                if isPresent {
                    if receiverName != vm.currentBuyer {
                        try await vm.uploadTransaction(buyerName: buyerName, receiverName: receiverName)
                        print("\(buyerName) bought coffee for \(receiverName)")
                    }
                }
            }
        }
    }
    
    /// Cache a person's present status.
    /// Populate web from cloud.
    /// Mark present people as present in the updated web.
    func refreshTransactions() {
        var cachedPresentStatus = [String:Bool]()
        for person in vm.coffeeculeMembers {
            cachedPresentStatus[person] = vm.relationshipWeb[person]?.isPresent
        }
        Task {
            var web = try await vm.populateWebFromCloud()
            for person in web {
                web[person.key]?.isPresent = cachedPresentStatus[person.key] ?? true
                //                vm.calculateCurrentBuyer(for: vm.relationshipWeb)
            }
            vm.relationshipWeb = web
        }
    }
    
}

// MARK: - Preview

struct CoffeeculeView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeculeView(vm: ViewModel())
    }
}
