//
//  ContentView.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/20/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = ViewModel()
    var body: some View {
        VStack {
            if vm.hasCoffeecule {
                CoffeeculeView(vm: vm)
            } else {
                JoinView(vm: vm)
            }
        }
        .task {
            vm.state = .loading
            vm.participantName = vm.shortenName(vm.repository.userName)
            vm.state = .loaded
            print("Done")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
