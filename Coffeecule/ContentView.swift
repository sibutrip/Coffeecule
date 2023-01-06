//
//  ContentView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/7/23.
//

import SwiftUI
import Charts

struct Person: Identifiable, Hashable {
    let id = UUID()
    var relationships: [String:Int]
    var isPresent = false
}

class PeopleModel {
    var people: [String:Person] =
    ["cory":Person(relationships: ["tariq":0,"tom":0,"ty":0,"zoe":0]),
     "tariq":Person(relationships: ["cory":0,"tom":0,"ty":0,"zoe":0]),
     "tom":Person(relationships: ["cory":0,"tariq":0,"ty":0,"zoe":0]),
     "ty":Person(relationships: ["cory":0,"tariq":0,"tom":0,"zoe":0]),
     "zoe":Person(relationships: ["cory":0,"tariq":0,"tom":0,"ty":0])]
}

class ViewModel: ObservableObject {
    @Published var people: [String:Person]
    @Published var transactions: [TransactionModel] = [] {
        didSet {
            generateRelationships()
        }
    }
    
    
    init() {
        people = PeopleModel().people
        fetchItems()
    }
    
    func generateRelationships() {
        for transaction in transactions {
            people[transaction.buyerName]?.relationships[transaction.receiverName]! -= 1
            people[transaction.receiverName]?.relationships[transaction.buyerName]! += 1
        }
    }
    
    var presentPeople = [String]()
    
    var presentPeopleDebt: [String:Int] {
        var presentPeopleDebt = [String:Int]()
        for giverName in presentPeople {
            var individualDebtCount = 0
            for receiverName in people[giverName]!.relationships {
                if presentPeople.contains(receiverName.key) {
                    individualDebtCount += receiverName.value
                }
            }
            presentPeopleDebt[giverName] = individualDebtCount
        }
        return presentPeopleDebt
    }
    
    var currentBuyer = "nobody"
    
    func calculateCurrentBuyer() {
        let sortedPeople = presentPeopleDebt.sorted { $0.1 > $1.1 }
        currentBuyer = sortedPeople.first?.key ?? "nobody"
    }
    
    func calculatePresentPeople() {
        var nextPresentPeople = [String]()
        for person in people {
            if person.value.isPresent {
                nextPresentPeople.append(person.key)
            }
        }
        presentPeople = nextPresentPeople
    }
    
    func buyCoffee() {
        for presentPerson in presentPeople {
            if presentPerson != currentBuyer {
                people[currentBuyer]?.relationships[presentPerson]! -= 1
                people[presentPerson]?.relationships[currentBuyer]! += 1
                addItem(buyerName: currentBuyer, receiverName: presentPerson)
                print("a coffee bought for \(presentPerson)")
            }
        }
        calculatePresentPeople()
        calculateCurrentBuyer()
    }
}

struct ContentView: View {
    @StateObject var vm = ViewModel()
    @State var buyCoffee = false
    var body: some View {
        NavigationView {
            Form {
                Section("who's getting coffee?") {
                    List(vm.people.keys.sorted(), id: \.self) { name in
                        Button {
                            vm.people[name]?.isPresent.toggle()
                            vm.calculatePresentPeople()
                            vm.calculateCurrentBuyer()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark")
                                    .opacity(vm.people[name]?.isPresent ?? false ? 1.0 : 0.0)
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
                    .alert("is \(vm.currentBuyer) buying coffee?", isPresented: $buyCoffee) {
                        HStack {
                            Button("yes", role: .destructive) {
                                vm.buyCoffee()
                            }
                            Button("no", role: .cancel) { }
                        }
                    }
                }.frame(maxWidth: .infinity)
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
            }.navigationTitle("Coffeecule")
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
