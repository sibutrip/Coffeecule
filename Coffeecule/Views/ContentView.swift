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
            if vm.personService.rootShare != nil {
                CoffeeculeView(vm: vm)
            } else {
                JoinView(vm: vm)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
