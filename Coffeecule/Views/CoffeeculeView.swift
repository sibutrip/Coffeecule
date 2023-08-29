//
//  ContentView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/7/23.
//
import SwiftUI
import Charts
import CloudKit

struct CoffeeculeView: View {
    @ObservedObject var vm: ViewModel
    @State var isBuying = false
    @State var processingTransaction = false
    @State var isSharing = false
    @State var isDeletingCoffeecule = false
    @State var couldntGetPermission = false
    @State var share: CKShare?
    @State var container: CKContainer?
    @State var viewingHistory = false
    @State var addingTransaction = false
    @Environment(\.editMode) private var editMode
    @State var chartScale: CGFloat = 0
    
    var body: some View {
        Form {
            WhosGettingCoffee(vm: vm, share: $share, container: $container, isSharing: $isSharing)
                .animation(.default, value: vm.relationships)
            itsTimeForPersonToGetCoffee
            buyCoffeeButton
            if vm.presentPeopleCount > 1 {
                relationshipWebChart
            }
            if self.editMode?.wrappedValue != .inactive {
                Section {
                    Button("Delete Coffeecule") {
                        isDeletingCoffeecule = true
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .environment(\.editMode, editMode)
        .navigationTitle(Title.activeTitle)
        .refreshable {
            Task {
                await vm.refreshData()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    addingTransaction = true
                } label: {
                    Label("add transaction", systemImage: "mug")
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewingHistory = true
                } label: {
                    Label("buying history", systemImage: "clock")
                }
            }
        }
        .sheet(isPresented: $isSharing) {
            if let share = share {
                CloudSharingView(share: share, container: container!)
            } else {
                EmptyView()
            }
        }
        .sheet(isPresented: $viewingHistory) {
            HistoryView(vm: vm)
        }
        .sheet(isPresented: $addingTransaction) {
            AddTransactionView(vm: vm, processingTransaction: $processingTransaction)
        }
        .alert("da app needz da permissionz", isPresented: $couldntGetPermission) {
            Button("ok den", role: .cancel) { couldntGetPermission = false}
        }
        .alert("Are you sure you want to delete your Coffeecule? This action is not reversable.", isPresented: $isDeletingCoffeecule) {
            HStack {
                Button("Yes", role: .destructive) {
                    Task {
                        do {
                            try await vm.deleteCoffeecule()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                Button("No", role: .cancel) {
                    isDeletingCoffeecule = false
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
                        processingTransaction = true
                        Task(priority: .userInitiated) {
                            await vm.buyCoffee(receivers:vm.presentPeople)
                            vm.createDisplayedDebts()
                            vm.calculateBuyer()
                            processingTransaction = false
                        }
                    }
                    Button("No", role: .cancel) {
                        isBuying = false
                    }
                }
            }
            .disabled(vm.currentBuyer.name == "nobody" || processingTransaction == true)
        }
    }
    
    var relationshipWebChart: some View {
        Section {
            chart(vm.displayedDebts)
                .frame(height: 100)
                .animation(.default, value: vm.presentPeopleCount)
                .onAppear { withAnimation { chartScale = 1 } }
                .onDisappear { withAnimation { chartScale = 0 } }
                .overlay {
                    if processingTransaction {
                        ZStack {
                            Color.gray.opacity(0.2)
                            ProgressView()
                        }
                    }
                }
        }
    }
    
    // MARK: - Toolbars
    
    var settingsToolbar: some View {
        EditButton()
    }
    
    
    var selectAllToolbar: some View {
        Button {
            for index in vm.relationships.indices {
                vm.relationships[index].isPresent = true
            }
        } label: {
            Text("Select All")
        }
    }
    func chart(_ debt: [Person : Int])  -> some View {
        let displayedDebts = debt
        if #available(iOS 16, *) {
            return Chart(displayedDebts.keys.sorted(), id: \.self) {
                BarMark(
                    x: .value("person", $0.name),
                    y: .value("cups bought", displayedDebts[$0] ?? 10)
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
        CoffeeculeView(vm: ViewModel())
    }
}

