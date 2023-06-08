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
            Button("join") { joining = true }
            Spacer()
            Button("create") { creating = true }
            Spacer()
        }
        .sheet(isPresented: $joining) {
            JoinView(vm: vm, couldNotJoinCule: $couldNotJoinCule, couldntCreateCule: $couldntCreateCule)
        }
        .sheet(isPresented: $creating) {
            CreateView(vm: vm, couldNotJoinCule: $couldNotJoinCule, couldntCreateCule: $couldntCreateCule)
            
        }
        .alert(vm.state.rawValue, isPresented: $couldNotJoinCule) {
            Button("ok den", role: .cancel) {
                couldNotJoinCule = false
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView(vm: ViewModel())
    }
}
