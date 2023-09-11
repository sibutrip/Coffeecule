//
//  OnboardingView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/28/23.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var vm: ViewModel
    
    @State private var couldNotJoinCule = false
    @State private var couldntCreateCule = false
    @State private var creating = false
    @State private var joining = false
    
    var body: some View {
        VStack {
            Spacer()
            Button("Create a new Coffecule") { creating = true }
            Spacer()
            Button("Join an existing Coffecule") { joining = true }
            Spacer()
        }
        .padding()
        .sheet(isPresented: $creating) {
            CreateView(vm: vm, couldNotJoinCule: $couldNotJoinCule, couldntCreateCule: $couldntCreateCule)
        }
        .alert(vm.state.rawValue, isPresented: $couldNotJoinCule) {
            Button("ok den", role: .cancel) {
                couldNotJoinCule = false
            }
        }
        .sheet(isPresented: $joining) {
            Text("Open a link from the owner of the Coffeecule to join")
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(vm: ViewModel())
    }
}
