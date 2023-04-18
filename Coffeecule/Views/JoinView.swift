//
//  JoinVoew.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/17/23.
//

import SwiftUI

struct JoinView: View {
    @ObservedObject var vm: ViewModel
    @State private var tryingToJoinACule = false
    @State private var couldntCreateCule = false
    
    var body: some View {
        if vm.state == .loaded {
            VStack {
                Button("join a coffeecule") {
                    Task {
                        guard let _ = try? await vm.joinCoffeecule(name: vm.participantName)
                        else {
                            print("cant join cule")
                            return
                        }
                    }
                }
                Button("create a cule") {
                    Task {
                        guard let _ = try? await vm.onCoffeeculeLoad() else {
                            couldntCreateCule = true
                            return
                        }
                        await vm.createCoffeecule()
                        await vm.refreshData()
                        vm.hasCoffeecule = true
                    }
                }
            }
            .alert("accept a cule invite to join a cule sorry", isPresented: $tryingToJoinACule) {
                Button("alrighty", role: .cancel) {
                    tryingToJoinACule = false
                }
            }
            .alert("couldnt make cule try again", isPresented: $couldntCreateCule) {
                Button("alrighty", role: .cancel) {
                    couldntCreateCule = false
                }
            }
        } else {
            ProgressView()
            
        }
    }
}

struct JoinView_Previews: PreviewProvider {
    static var previews: some View {
        JoinView(vm: ViewModel())
    }
}
