//
//  SomeoneElseBuying.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI

struct SomeoneElseBuying: View {
    @ObservedObject var vm: ViewModel
    @Binding var someoneElseBuying: Bool
    @Binding var isBuying: Bool
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
                        ForEach($vm.relationships) { relationship in
                            if relationship.wrappedValue.isPresent {
                                Button {
                                    vm.currentBuyer = relationship.wrappedValue.person
                                } label: {
                                    MemberView(vm: vm, relationship: relationship, someoneElseBuying: true)
                                }
                            }
                        }
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            someoneElseBuying = false
                        }
                    }
                }
                if hasBuyer {
                    let transition = AnyTransition.move(edge: .bottom)
                    Button { 
                        isBuying = true
                    } label: {
                        Text("\(vm.currentBuyer.name) is buying")
                            .font(.title2)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .background(.regularMaterial)
                    .transition(transition)
                }
            }
            .animation(.default, value: hasBuyer)
            .navigationTitle(someoneElseBuying ? "Who's Buying?" : "Who's Here?")
        }
    }
}

#Preview {
    SomeoneElseBuying(vm: ViewModel(), someoneElseBuying: .constant(true), isBuying: .constant(false))
}
