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
    @State private var joinIsDisabled = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                NavigationLink("join a coffeecule") {
                    List {
                        TextField("join as...", text: $vm.participantName)
                            .onSubmit {
                                self.joinIsDisabled = true
                                Task(priority: .userInitiated) {
                                    await vm.joinCoffeecule()
                                    switch vm.state {
                                    case .loading:
                                        break
                                    case .loaded:
                                        break
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
                                    self.joinIsDisabled = false
                                }
                            }
                        Button("join") {
                            self.joinIsDisabled = true
                            Task(priority: .userInitiated) {
                                await vm.joinCoffeecule()
                                switch vm.state {
                                case .loading:
                                    break
                                case .loaded:
                                    break
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
                                self.joinIsDisabled = false
                            }
                        }
                        .navigationBarBackButtonHidden(joinIsDisabled)
                        .disabled(joinIsDisabled || vm.participantName.isEmpty)
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
                            .onSubmit {
                                self.joinIsDisabled = true
                                Task(priority: .userInitiated) {
                                    await vm.joinCoffeecule()
                                    switch vm.state {
                                    case .loading:
                                        break
                                    case .loaded:
                                        break
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
                                    self.joinIsDisabled = false
                                }
                            }
                        Button("create") {
                            self.joinIsDisabled = true
                            Task(priority: .userInitiated) {
                                await vm.createCoffeecule()
                                switch vm.state {
                                case .loading:
                                    break
                                case .loaded:
                                    break
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
                                self.joinIsDisabled = false
                            }
                        }
                        .navigationBarBackButtonHidden(joinIsDisabled)
                        .disabled(joinIsDisabled || vm.participantName.isEmpty)
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
    }
}

struct JoinView_Previews: PreviewProvider {
    static var previews: some View {
        JoinView(vm: ViewModel())
    }
}
