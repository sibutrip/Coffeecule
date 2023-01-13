//
//  ContentView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/7/23.
//

import SwiftUI
import Charts

struct TransactionCache {
    var buyerName: String
    var receiverName: String
}

struct Relationship {
    var isPresent = false
    var coffeesOwed = 0
}

struct BuyerInfo: Codable {
    var isPresent = false
    var coffeesOwed = 0
    var relationships = [String: Int]()
}

struct JSONUtility {
    public func encodeCoffeeculeMembers(for members: [String]) -> Data {
        guard let encodedData = try? JSONEncoder().encode(members) else { return Data() }
        return encodedData
    }
    
    public func decodeCoffeeculeMembers(for members: Data) -> [String] {
        guard let decodedData = try? JSONDecoder().decode([String].self, from: members) else { return [String]() }
        return decodedData
    }
    
    public func encodeWeb(for relationshipWeb: [String:BuyerInfo]) -> Void {
        do {
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("relationshipWeb.json")
            
            try JSONEncoder()
                .encode(relationshipWeb)
                .write(to: fileURL)
        }
        catch {
            print("error writing data")
        }
    }
    
    public func decodeWeb() -> [String:BuyerInfo] {
        do {
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("relationshipWeb.json")
            
            let data = try Data(contentsOf: fileURL)
            var pastData = try JSONDecoder().decode([String:BuyerInfo].self, from: data)
//            for person in pastData {
//                pastData[person.key]?.isPresent = false
//            }
//            print(pastData)
            return pastData
        } catch {
            print("error reading web data")
            return [:]
        }
    }
    
    public func encodeCache(for transactions: [[String]]) -> Void {
        do {
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("cachedTransactions.json")
            
            try JSONEncoder()
                .encode(transactions)
                .write(to: fileURL)
        } catch {
            print("error writing data")
        }
    }
    
    public func decodeCache() -> [[String]] {
        do {
            let fileURL = try FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
                .appendingPathComponent("cachedTransactions.json")
            
            let data = try Data(contentsOf: fileURL)
            let cache = try JSONDecoder().decode([[String]].self, from: data)
            return cache
        } catch {
            print("error reading cache data")
            return []
        }
    }
    
}

class ViewModel: ObservableObject {
    var relationshipWeb: [String:BuyerInfo]? = nil
    {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    @AppStorage("coffeeculeMembers") var coffeeculeMembersData: Data = Data()
    @AppStorage("userHasCoffecule") var userHasCoffecule = false
    var cloudContainer = "Transactions"
    var isConnectedToCloud = false
    var cachedTransactions = [[String]]() {
        didSet {
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
        }
    }
    var webIsPopulated = false
//    var cachedTransactions = [["Tariq","Cory"]]
    var userHasCoffeeculeOnLaunch = false
    var addedPeople = [String]() {
        didSet {
            createNewCoffeecule(for: addedPeople)
        }
    }
    @Published var transactions: [TransactionModel] = []
    
    init() {
        userHasCoffeeculeOnLaunch = userHasCoffecule
        if userHasCoffecule {
            let people = JSONUtility().decodeCoffeeculeMembers(for: coffeeculeMembersData)
            generateRelationshipWeb(for: people)
            // create empty web. will populate later with cached web or icloud transactions
            checkiCloudStatus()
        }
    }
    
    var presentPeople = [String]()
    
    var presentPeopleDebt: [String:Int]
    {
        var presentPeopleDebt = [String:Int]()
        for giverName in presentPeople {
            var individualDebtCount = 0
            for receiverName in relationshipWeb![giverName]!.relationships {
                if presentPeople.contains(receiverName.key) {
                    individualDebtCount += receiverName.value
                }
            }
            presentPeopleDebt[giverName] = individualDebtCount
        }
        return presentPeopleDebt
    }
    
    var currentBuyer = "nobody"
    
    func calculatePresentPeopleDebt() {
        var presentPeopleDebt = [String:Int]()
        for giverName in presentPeople {
            var individualDebtCount = 0
            if let relationshipWeb = relationshipWeb {
                if let buyerInfo = relationshipWeb[giverName] {
                    for receiverName in buyerInfo.relationships {
                        if presentPeople.contains(receiverName.key) {
                            individualDebtCount += receiverName.value
                        }
                    }
                }
            }
            presentPeopleDebt[giverName] = individualDebtCount
        }
        //        self.presentPeopleDebt = presentPeopleDebt
//        print(presentPeopleDebt)
    }
    
    
    public func createNewCoffeecule(for addedMembers: [String]) {
        generateRelationshipWeb(for: addedMembers)
        coffeeculeMembersData = JSONUtility().encodeCoffeeculeMembers(for: addedMembers)
        self.userHasCoffecule = true
    }
    
    func generateRelationshipWeb(for people: [String]) {
        /// creates empty web template
        var relationshipWeb = [String:BuyerInfo]()
        for buyer in people {
            var buyerInfo = BuyerInfo()
            for receiver in people {
                if receiver != buyer {
                    buyerInfo.relationships[receiver] = 0
                }
            }
            relationshipWeb[buyer] = buyerInfo
        }
//        JSONUtility().encodeWeb(for: relationshipWeb)
        self.relationshipWeb = relationshipWeb
    }
    
    enum RelationshipWebSource {
        case Cache, Cloud
    }
    
    func populateRelationshipWeb(from source: RelationshipWebSource) {
        switch source {
        case .Cloud:
            for transaction in transactions {
//                print(transaction.buyerName)
                relationshipWeb?[transaction.buyerName]?.relationships[transaction.receiverName]! -= 1
                relationshipWeb?[transaction.receiverName]?.relationships[transaction.buyerName]! += 1
            }
        case .Cache:
            self.relationshipWeb = JSONUtility().decodeWeb()
            print("loaded from cache")
            print(self.relationshipWeb)
//            print(relationshipWeb)
//            for transaction in cachedTransactions {
//                relationshipWeb?[transaction[0]]?.relationships[transaction[1]]! -= 1
//                relationshipWeb?[transaction[1]]?.relationships[transaction[0]]! -= 1
//                print("cached transaction added to web")
//            }
        }
//        webIsPopulated = true
    }
    
    func calculateCurrentBuyer() {
        let sortedPeople = presentPeopleDebt.sorted { $0.1 > $1.1 }
        currentBuyer = sortedPeople.first?.key ?? "nobody"
    }
    
    func calculatePresentPeople() {
        var nextPresentPeople = [String]()
        for person in relationshipWeb! {
            if person.value.isPresent {
                nextPresentPeople.append(person.key)
            }
        }
        presentPeople = nextPresentPeople
    }
    
    func buyCoffee() {
        for presentPerson in presentPeople {
            if presentPerson != currentBuyer {
                relationshipWeb![currentBuyer]?.relationships[presentPerson]! -= 1
                relationshipWeb![presentPerson]?.relationships[currentBuyer]! += 1
                addItem(buyerName: currentBuyer, receiverName: presentPerson)
                print("\(currentBuyer) bought a coffee bought for \(presentPerson)")
            }
        }
        calculatePresentPeople()
        calculateCurrentBuyer()
        JSONUtility().encodeWeb(for: relationshipWeb!)
        print(relationshipWeb)
    }
}

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
