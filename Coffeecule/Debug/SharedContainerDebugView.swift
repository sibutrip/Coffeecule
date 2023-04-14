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
            List(vm.people, id: \.self) { person in
                HStack {
                    Text(person.name)
                    Text(person.coffeesOwed.description)
                }
            }
            Button("refetch cule") {
                Task {
                    await vm.refreshData()
                }
            }
            Button("create cule") {
                Task {
                    await vm.createCoffeecule(name: vm.participantName)
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
        }.sheet(isPresented: $isSharing) {
            CloudSharingView(repo: vm.personService)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
