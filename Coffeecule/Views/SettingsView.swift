//
//  SettingsView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/19/23.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: ViewModel
    @State var tappedDelete = false
    var body: some View {
        VStack {
            List {
                Button(role: .destructive) {
                    tappedDelete = true
                } label: {
                    Text("Delete My Coffeecule")
                }
            }
            .alert("Are you sure you want to delete your Coffeecule?", isPresented: $tappedDelete, actions: {
                HStack {
                    Button(role: .destructive) {
                        // delete coffeecule and return to "create a cule" view
                        tappedDelete = false
                        vm.userHasCoffeeculeOnLaunch = false
                    } label: {
                        Text("Yes")
                    }
                    Button(role: .cancel) {
                        tappedDelete = false
                    } label: {
                        Text("No")
                    }
                }
            }, message: {
                Text("You cannot undo this action")
            })
        }.frame(maxHeight: .infinity, alignment: .center)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(vm: ViewModel())
    }
}
