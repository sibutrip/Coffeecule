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
            if vm.state != .loading {
                VStack {
                    Spacer()
                    NavigationLink("join a coffeecule") {
                        List {
                            TextField("join as...", text: $vm.participantName)
                            Button("join") {
                                self.joinIsDisabled = true
                                Task {
                                    await vm.createCoffeecule()
                                    self.joinIsDisabled = false
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
                                }
                            }
                            .disabled(joinIsDisabled)
                        }
                        .navigationTitle(Title.shared.activeTitle)
                        .overlay {
                            if joinIsDisabled {
                                ProgressView()
                            }
                        }
                    }
                    
                    Spacer()
                    NavigationLink("create a coffeecule") {
                        List {
                            TextField("create as...", text: $vm.participantName)
                            Button("create") {
                                self.joinIsDisabled = true
                                Task {
                                    await vm.createCoffeecule()
                                    self.joinIsDisabled = false
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
                                }
                            }
                            .disabled(joinIsDisabled)
                        }
                        .navigationTitle(Title.shared.activeTitle)
                        .overlay {
                            if joinIsDisabled {
                                ProgressView()
                            }
                        }
                    }
                    Spacer()
                }
                
                .alert(vm.state.rawValue, isPresented: $couldNotJoinCule) {
                    Button("ok den", role: .cancel) {
                        couldNotJoinCule = false
                        joinIsDisabled = false
                    }
                }
            }
            else {
                ProgressView()
            }
        }
    }
}

struct JoinView_Previews: PreviewProvider {
    static var previews: some View {
        JoinView(vm: ViewModel())
    }
}
