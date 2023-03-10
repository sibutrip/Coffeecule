//
//  ContentView.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/20/23.
//

import SwiftUI

struct ContentView: View {
    @StateObject var vm = ViewModel(readWriter: ReadWrite.shared)
    var body: some View {
        if vm.hasCoffeecule {
            CoffeeculeView(vm: vm)
        } else {
            OnboardingView(vm: vm)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
