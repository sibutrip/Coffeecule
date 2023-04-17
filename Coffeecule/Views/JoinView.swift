//
//  JoinVoew.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/17/23.
//

import SwiftUI

struct JoinView: View {
    @ObservedObject var vm: ViewModel
    var body: some View {
        if vm.state == .loaded {
            Button("join as \(vm.participantName)") {
                Task {
                    await vm.joinCoffeecule(name: vm.participantName)
                    await vm.refreshData()
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
