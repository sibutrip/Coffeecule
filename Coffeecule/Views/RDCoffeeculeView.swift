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
    @State var viewingHistory = false
    @State var customizingCup = false
    let columns: [GridItem]
    var hasBuyer: Bool {
        vm.currentBuyer != Person()
    }
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach($vm.relationships) { relationship in
                                MemberView(vm: vm, relationship: relationship)
                            }
                        }
                    }
                    if hasBuyer {
                        let transition = AnyTransition.move(edge: .bottom)
                        EqualWidthVStackLayout(spacing: 10) {
                            Button { } label: {
                                Text("\(vm.currentBuyer.name) is buying")
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            Button { } label: {
                                Text("Someone else is buying")
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding()
                        .padding(.bottom, 30)
                        .frame(width: geo.size.width)
                        .background(.regularMaterial)
                        .transition(transition)
                    }
                }
                .animation(.default, value: hasBuyer)
                .navigationTitle("Who's Here?")
            }
            .toolbar {
                ToolbarItem {
                    Button {
                        customizingCup = true
                    } label: {
                        Label("Customize Your Cup", systemImage: "cup.and.saucer")
                    }
                }
                
                ToolbarItem {
                    Button{
                        viewingHistory = true
                    } label: {
                        Label("Transaction History", systemImage: "dollarsign.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $viewingHistory) {
                HistoryView(vm: vm)
            }
            .sheet(isPresented: $customizingCup) {
                GeometryReader { geo in
                    CustomizeCupView(vm: vm)
                }
            }
        }
    }
    init(vm: ViewModel, geo: GeometryProxy) {
        self.vm = vm
        let maxColumnWidth = geo.size.width / 4
        columns = [
            GridItem(.flexible(minimum: 10, maximum: .infinity)),
            GridItem(.flexible(minimum: 10, maximum: .infinity))
        ]
    }
}
