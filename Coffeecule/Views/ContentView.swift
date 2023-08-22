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
    var body: some View {
        NavigationStack {
            VStack {
                if vm.state == .loading {
                    ProgressView()
                } else {
                    if vm.hasShare == true {
                        CoffeeculeView(vm: vm)
                    } else {
                        OnboardingView(vm: vm)
                    }
                }
            }
            .sheet(isPresented: $appAccess.accessedFromShare) {
                JoinSheet(vm: vm)
            }
            .alert(isPresented: $vm.cloudAuthenticationDidFail, error: vm.cloudError) { _ in
                Button("okay") { }
            } message: { error in
                Text(error.recoverySuggestion ?? "")
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
