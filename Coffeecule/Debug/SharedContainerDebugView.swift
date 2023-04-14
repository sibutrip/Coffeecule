//
//  ContentView.swift
//  SharedContainer
//
//  Created by Cory Tripathy on 3/29/23.
//

import SwiftUI

struct ContentView: View {
    @State var isSharing = false
    @StateObject var vm = ViewModel()
    var body: some View {
        VStack {
            Text("your name is: \(vm.participantName)")
            List {
                ForEach(vm.people.indices, id: \.self) { index in
                    let person = vm.people[index]
                    Button {
                        vm.people[index].isPresent.toggle()
                        vm.createDisplayedDebts()
                        vm.calculateBuyer()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                                .opacity(vm.people[index].isPresent ? 1.0 : 0.0)
                            Text("\(person.name)")
                                .foregroundColor(.black)
                            Text(person.coffeesOwed.description)
                        }
                    }
                }
            }
            HStack {
                VStack {
                    Button("refetch cule") {
                        Task {
                            await vm.refreshData()
                        }
                    }
                    Button("create cule") {
                        Task {
                            await vm.createCoffeecule()
                        }
                    }
                    Button("share cule") {
                        Task {
                            await vm.shareCoffeecule()
                            isSharing = true
                        }
                    }
                    Button("join as \(vm.participantName)") {
                        Task {
                            await vm.joinCoffeecule(name: vm.participantName)
                        }
                    }
                }
                Spacer()
                VStack {
                    Text("current buyer is \(vm.currentBuyer.name)")
                    Button("buy coffee") {
                        Task {
                            await vm.buyCoffee()
                            vm.createDisplayedDebts()
                            vm.calculateBuyer()
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $isSharing) {
            CloudSharingView(repo: vm.personService)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
