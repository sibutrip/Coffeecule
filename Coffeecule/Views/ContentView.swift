//
//  ContentView.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/20/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = ViewModel()
    @State private var couldNotGetPermission = false
    var body: some View {
        VStack {
            if vm.hasCoffeecule {
                CoffeeculeView(vm: vm)
            } else {
                JoinView(vm: vm)
            }
        }
        .task {
            do {
                vm.state = .loading
                _ = try await vm.repository.requestAppPermission()
                vm.repository.userName = try? await vm.repository.fetchiCloudUserName()
                vm.participantName = vm.shortenName(vm.repository.userName)
                vm.state = .loaded
                print("name is \(vm.participantName)")
            } catch {
                couldNotGetPermission = true
            }
        }
        .alert("could not get app permission", isPresented: $couldNotGetPermission) {
            Button("okay") {
                couldNotGetPermission = false
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
