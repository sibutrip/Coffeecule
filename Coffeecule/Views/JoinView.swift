//
//  JoinView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/28/23.
//

import SwiftUI

#warning("add a obs obj to control popping to root")

struct JoinView: View {
    @ObservedObject var vm: ViewModel
    @State var joinIsDisabled = false
    @State var couldNotJoinCule = false
    @Environment(\.dismiss) var dismiss: DismissAction

    var body: some View {
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
                joinIsDisabled = false
            }
            .disabled(joinIsDisabled || vm.participantName.isEmpty)
        }
        .alert("\(vm.state.rawValue)", isPresented: $couldNotJoinCule) {
            Button("womp womp") {
                joinIsDisabled = false
            }
        }
    }
}

//struct JoinView_Previews: PreviewProvider {
//    static var previews: some View {
//        JoinView(vm: ViewModel(), dismiss: <#Binding<DismissAction>#>)
//    }
//}
