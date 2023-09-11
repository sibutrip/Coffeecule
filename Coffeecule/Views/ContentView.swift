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
    @State var customizingCup = false
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack {
                    if vm.state == .loading {
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        if vm.hasShare == true {
                            RDCoffeeculeView(vm: vm, geo: geo)
                        } else {
                            OnboardingView(vm: vm)
                        }
                    }
                }
            }
            .sheet(isPresented: $appAccess.accessedFromShare) {
                JoinSheet(vm: vm, customizingCup: $customizingCup)
            }
            .sheet(isPresented: $customizingCup) {
                CustomizeCupView(vm: vm)
            }
            .alert(isPresented: $vm.cloudAuthenticationDidFail, error: vm.cloudError) { _ in
                Button("okay") { }
            } message: { error in
                Text(error.recoverySuggestion ?? "")
            }
            
            .alert(isPresented: $vm.personRecordCreationDidFail, error: vm.personError) { _ in
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
