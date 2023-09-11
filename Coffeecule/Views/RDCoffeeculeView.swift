//
//  RDCoffeeculeView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/7/23.
//

import Foundation
import SwiftUI

struct RDCoffeeculeView: View {
    @ObservedObject var vm: ViewModel
    let columns: [GridItem]
    @State var someoneElseBuying = false
    var hasBuyer: Bool {
        vm.currentBuyer != Person()
    }
    var body: some View {
        NavigationStack {
            if !someoneElseBuying {
                AllMembersView(vm: vm, someoneElseBuying: $someoneElseBuying)
            } else {
                SomeoneElseBuying(vm: vm)
            }
        }.animation(.default, value: someoneElseBuying)
    }
    init(vm: ViewModel, geo: GeometryProxy) {
        self.vm = vm
        columns = [
            GridItem(.flexible(minimum: 10, maximum: .infinity)),
            GridItem(.flexible(minimum: 10, maximum: .infinity))
        ]
    }
}
