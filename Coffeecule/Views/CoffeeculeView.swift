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
    @State var isBuying = false
    var body: some View {
        NavigationView {
            Form {
                WhosGettingCoffee(vm: vm)
                itsTimeForPersonToGetCoffee
                buyCoffeeButton
                relationshipWebChart
            }
            .navigationTitle("Coffeecule")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    selectAllToolbar
                }
            }
        }
        .overlay {
            ZStack {
                switch vm.state {
                case .loading:
                    Color.gray.opacity(0.3)
                    ProgressView()
                default:
                    EmptyView()
                }
            }
            .ignoresSafeArea()
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
    
    var itsTimeForPersonToGetCoffee: some View {
        Section {
            VStack(alignment: .center) {
                Spacer()
                Text("it's time for")
                Text("\(vm.currentBuyer.name)").font(.largeTitle)
                    .animation(.default.speed(3.0), value: vm.currentBuyer)
                Text("to buy coffee")
                Spacer()
            }.frame(maxWidth: .infinity)
        }
    }
    
    var buyCoffeeButton: some View {
        Section {
            Button("buy coffee") {
                isBuying = true
            }.alert("Is \(vm.currentBuyer.name) buying coffee?", isPresented: $isBuying) {
                HStack {
                    Button("Yes", role: .destructive) {
                        Task(priority: .userInitiated) {
                            vm.state = .loading
                            vm.buyCoffee()
//                            await vm.refreshTransactions()
                            vm.calculateBuyer()
                            vm.state = .loaded
                        }
                    }
                    Button("No", role: .cancel) {
                        isBuying = false
                    }
                }
            }
            .disabled(vm.currentBuyer.name == "nobody")
        }
    }
    
    var relationshipWebChart: some View {
        VStack {
            Chart(vm.displayedDebts.keys.sorted(), id: \.self) {
                BarMark(
                    x: .value("person", $0.name),
                    y: .value("cups bought", vm.displayedDebts[$0] ?? 0)
                )
            }
            
        }
        .frame(height: 100)
        .animation(.default, value: vm.displayedDebts)
    }
    
    // MARK: - Toolbars
    
    var settingsToolbar: some View {
        EditButton()
    }
    
    
    var selectAllToolbar: some View {
        Button {
            for index in vm.people.indices {
                vm.people[index].isPresent = true
            }
        } label: {
            Text("Select All")
        }
    }  
}

// MARK: - Preview

struct CoffeeculeView_Previews: PreviewProvider {
    static var previews: some View {
        CoffeeculeView(vm: ViewModel(readWriter: ReadWrite.shared))
    }
}

