////
////  ContentView.swift
////  CoffeeculeTest
////
////  Created by Cory Tripathy on 1/27/23.
////
//
//import SwiftUI
//import Foundation
//
//struct DEBUGCoffeeculeView: View {
//    @ObservedObject var vm: ViewModel
//    var body: some View {
//        NavigationView {
//            VStack {
//                switch vm.state {
//                case .loaded, .loading:
//                    VStack {
//                        ForEach($vm.people) { person in
//                            Button {
//                                person.isPresent.wrappedValue.toggle()
//                                vm.calculateBuyer()
//                            } label: {
//                                HStack {
//                                    Text(person.wrappedValue.name)
//                                    Text(person.wrappedValue.isPresent.description)
//                                }
//                            }
//                        }
//                        Picker("current Buyer", selection: $vm.displayedBuyers) {
//                            Text("ah")
//                        }
//                        
//                        //                        Text(vm.currentBuyer.name)
//                        Button("buy") {
////                            vm.buyCoffee()
//                            for person in vm.people {
//                                print(person.name,person.coffeesOwed)
//                            }
//                        }
//                    }
//                case .error(let error):
//                    Text("\(error.localizedDescription)")
//                case .noCoffeecule:
//                    OnboardingView(vm: vm)
//                case .noPermission:
//                    Text("Please enable permission in cloud")
//                }
//            }.navigationTitle(navTitle)
//        }
//    }
//    
//    
//    var navTitle: String {
//        switch vm.state {
//        case .loading:
//            return "loading"
//        case .loaded:
//            return "loaded"
//        case .noCoffeecule:
//            return "no coffeecule"
//        case .noPermission:
//            return "no permission"
//        case .error(let error):
//            return error.localizedDescription
//        }
//    }
//}
//
//
//struct DEBUGCoffeeculeView_Previews: PreviewProvider {
//    static var previews: some View {
//        DEBUGCoffeeculeView(vm: ViewModel(readWriter: DummyReadWriter.shared))
//    }
//}
