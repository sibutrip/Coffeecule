////
////  MainView.swift
////  Coffeecule
////
////  Created by Cory Tripathy on 1/13/23.
////

import Foundation
import SwiftUI

struct ContentView: View {
    @StateObject var vm = ViewModel()
    
    var body: some View {
        if vm.userHasCoffeeculeOnLaunch {
            CoffeeculeView(vm: vm)
        } else {
//            EmptyView()
            OnboardingView(vm: vm)
        }
    }
}
