//
//  ContentView.swift
//  SharedContainer
//
//  Created by Cory Tripathy on 3/29/23.
//

import SwiftUI

struct DebugView: View {
    @State var isSharing = false
    @StateObject var vm = ViewModel()
    var body: some View {
        VStack {
            Text("your name is: \(vm.participantName)")
            List {
                ForEach(vm.relationships.indices, id: \.self) { index in
                    let person = vm.relationships[index]
                    Button {
                        vm.relationships[index].isPresent.toggle()
                        vm.createDisplayedDebts()
                        vm.calculateBuyer()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                                .opacity(vm.relationships[index].isPresent ? 1.0 : 0.0)
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
                            do {
                                try await vm.createCoffeecule()
                            } catch {
                                print(error.localizedDescription)
                            }
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
                            do {
                                let _ = try await vm.joinCoffeecule()
                            } catch {
                                print(error.localizedDescription)
                            }
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
            CloudSharingView()
        }
    }
}

struct DebugView_Previews: PreviewProvider {
    static var previews: some View {
        DebugView()
    }
}
