//
//  JoinVoew.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/17/23.
//

import SwiftUI

struct JoinView: View {
    @ObservedObject var vm: ViewModel
    @State private var couldNotJoinCule = false
    @State private var couldntCreateCule = false
    @State private var joinIsDisabled = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                NavigationLink("join a coffeecule") {
                    List {
                        TextField("join as...", text: $vm.participantName)
                        Button("join") {
                            Task {
                                joinIsDisabled = true
                                await vm.joinCoffeecule()
                                switch vm.state {
                                case .loading:
                                    return
                                case .loaded:
                                    return
                                case .noPermission:
                                    couldNotJoinCule = true
                                case .nameFieldEmpty:
                                    couldNotJoinCule = true
                                case .nameAlreadyExists:
                                    couldNotJoinCule = true
                                case .noShareFound:
                                    couldNotJoinCule = true
                                case .noSharedContainerFound:
                                    couldNotJoinCule = true
                                case .culeAlreadyExists:
                                    couldNotJoinCule = true
                                }
                                joinIsDisabled = false
                            }
                        }
                        .disabled(joinIsDisabled)
                    }
                    .navigationTitle(Title.shared.activeTitle)
                    .overlay {
                        if vm.state == .loading {
                            ProgressView()
                        }
                    }
                }
                
                .task {
                    await vm.refreshData()
                }
                .alert(vm.state.rawValue, isPresented: $couldNotJoinCule) {
                    Button("ok den", role: .cancel) {
                        couldNotJoinCule = false
                    }
                }
                
                Spacer()
                NavigationLink("create a coffeecule") {
                    List {
                        TextField("create as...", text: $vm.participantName)
                        Button("create") {
                            Task {
                                joinIsDisabled = true
                                await vm.createCoffeecule()
                                switch vm.state {
                                case .loading:
                                    return
                                case .loaded:
                                    couldNotJoinCule = true
                                case .noPermission:
                                    couldNotJoinCule = true
                                case .nameFieldEmpty:
                                    couldNotJoinCule = true
                                case .nameAlreadyExists:
                                    couldNotJoinCule = true
                                case .noShareFound:
                                    couldNotJoinCule = true
                                case .noSharedContainerFound:
                                    couldNotJoinCule = true
                                case .culeAlreadyExists:
                                    couldNotJoinCule = true
                                }
                                joinIsDisabled = false
                            }
                        }
                        .disabled(joinIsDisabled)
                    }
                    .navigationTitle(Title.shared.activeTitle)
                    .overlay {
                        if vm.state == .loading {
                            ProgressView()
                        }
                    }
                }
                Spacer()
            }
        }
    }
}

struct JoinView_Previews: PreviewProvider {
    static var previews: some View {
        JoinView(vm: ViewModel())
    }
}
