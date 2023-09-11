//
//  AllMembersView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI

struct AllMembersView: View {
    @ObservedObject var vm: ViewModel
    @State private var viewingHistory = false
    @State private var customizingCup = false
    @Binding var someoneElseBuying: Bool
    private let columns = [
        GridItem(.flexible(minimum: 10, maximum: .infinity)),
        GridItem(.flexible(minimum: 10, maximum: .infinity))
    ]
    var hasBuyer: Bool {
        vm.currentBuyer != Person()
    }
    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: columns) {
                        ForEach($vm.relationships) { $relationship in
                            Button {
                                relationship.isPresent.toggle()
                            } label: {
                                MemberView(vm: vm, relationship: $relationship)
                            }
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
                        Button {
                            someoneElseBuying = true
                        } label: {
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
                Button {
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
        }    }
}

#Preview {
    AllMembersView(vm: ViewModel(), someoneElseBuying: .constant(false))
}
