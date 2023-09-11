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
            EqualWidthVStackLayout(spacing: 200) {
                Button { creating = true } label: {
                    Text("Create a new Coffecule")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                Button { joining = true } label: {
                    Text("Join an existing Coffecule")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
