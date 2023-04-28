//
//  ContentView.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/20/23.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appAccess: AppAccess
    @StateObject var vm = ViewModel()
    @State private var couldNotGetPermission = false
    @State private var isLoading = true
    var body: some View {
        NavigationStack {
            VStack {
                if vm.hasShare == true {
                    CoffeeculeView(vm: vm)
                } else {
                    if isLoading {
                        EmptyView()
                    } else {
                        OnboardingView(vm: vm)
                    }
                }
            }
            .task {
                isLoading = true
                await vm.refreshData()
                isLoading = false
            }
            .sheet(isPresented: $appAccess.accessedFromShare) {
                JoinSheet(vm: vm, isLoading: $isLoading)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                } else {
                    EmptyView()
                }
        }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(AppAccess(accessedFromShare: false))
        ContentView().environmentObject(AppAccess(accessedFromShare: true))
    }
}
