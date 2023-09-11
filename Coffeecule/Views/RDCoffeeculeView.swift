//
//  RDCoffeeculeView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/7/23.
//

import Foundation
import SwiftUI

struct RDCoffeeculeView: View {
    @Environment(\.editMode) var editMode
    @ObservedObject var vm: ViewModel
    let columns: [GridItem]
    @State var someoneElseBuying = false
    @State var isBuying = false
    @State var isDeletingCoffeecule = false
    var hasBuyer: Bool {
        vm.currentBuyer != Person()
    }
    var body: some View {
        NavigationStack {
            Group {
                if !someoneElseBuying {
                    AllMembersView(vm: vm, someoneElseBuying: $someoneElseBuying, isBuying: $isBuying)
                } else {
                    SomeoneElseBuying(vm: vm, someoneElseBuying: $someoneElseBuying, isBuying: $isBuying)
                }
            }
            .refreshable {
                Task {
                    await vm.refreshData()
                }
            }
        }
        .alert("Is \(vm.currentBuyer.name) buying coffee?", isPresented: $isBuying) {
            HStack {
                Button("Yes") {
                    Task(priority: .userInitiated) {
                        await vm.buyCoffee(receivers:vm.presentPeople)
                    }
                    someoneElseBuying = false
                }
                Button("Cancel", role: .cancel) {
                    isBuying = false
                }
            }
        }
        .animation(.default, value: someoneElseBuying)
    }
    init(vm: ViewModel, geo: GeometryProxy) {
        self.vm = vm
        columns = [
            GridItem(.flexible(minimum: 10, maximum: .infinity)),
            GridItem(.flexible(minimum: 10, maximum: .infinity))
        ]
    }
}
