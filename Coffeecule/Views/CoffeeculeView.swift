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
    @State var isSharing = false
    var body: some View {
        NavigationView {
            Form {
                WhosGettingCoffee(vm: vm)
                itsTimeForPersonToGetCoffee
                buyCoffeeButton
                relationshipWebChart
            }
            .navigationTitle(Title.shared.activeTitle)
            .refreshable {
                Task { await vm.backgroundUpdateCloud() }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    shareToolbar
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isSharing) {
                CloudSharingView(share: Repository.shared.ckShare!, record: Repository.shared.rootRecord!)
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
            
            Button {
                isBuying = true
            } label: {
                switch vm.state {
                case .loaded:
                    Text("Buy Coffee")
                default:
                    ProgressView()
                }
            }
            .frame(maxWidth: .infinity)
            .alert("Is \(vm.currentBuyer.name) buying coffee?", isPresented: $isBuying) {
                HStack {
                    Button("Yes", role: .destructive) {
                        Task(priority: .userInitiated) {
                            vm.buyCoffee()
                            vm.calculateBuyer()
                        }
                    }
                    Button("No", role: .cancel) {
                        isBuying = false
                    }
                }
            }
            .disabled(vm.currentBuyer.name == "nobody" || vm.state != .loaded )
        }
    }
    
    var relationshipWebChart: some View {
        VStack {
            chart(vm.displayedDebts)
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
    
    var shareToolbar: some View {
        Button {
        isSharing = true
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }
    
    func chart(_ debt: [Person : Int])  -> some View {
        let displayedDebts = debt
        
        if #available(iOS 16, *) {
            
            return Chart(displayedDebts.keys.sorted(), id: \.self) {
                BarMark(
                    x: .value("person", $0.name),
                    y: .value("cups bought", displayedDebts[$0] ?? 0)
                ).foregroundStyle(displayedDebts[$0] ?? 0 > 0 ? .blue : .red)
            }
        } else {
            return EmptyView()
        }
    }
}
    
    // MARK: - Preview
    
    struct CoffeeculeView_Previews: PreviewProvider {
        static var previews: some View {
            CoffeeculeView(vm: ViewModel(readWriter: ReadWrite.shared))
        }
    }
    
