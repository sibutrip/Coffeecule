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
    @State private var isLoading = false
    var body: some View {
        VStack {
            if vm.hasShare == true {
                #error("if you accept a cule but dont create a profile, you wont be able to create your person")
                CoffeeculeView(vm: vm)
            } else {
                if isLoading {
                    EmptyView()
                } else {
                    JoinView(vm: vm)
                }
            }
        }
        .overlay {
            if isLoading {
                ProgressView()
            } else {
                EmptyView()
            }
        }
        .task {
            isLoading = true
            await vm.refreshData()
            isLoading = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
