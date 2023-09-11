//
//  SomeoneElseBuying.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI

struct SomeoneElseBuying: View {
    @ObservedObject var vm: ViewModel
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
                                MemberView(vm: vm, relationship: relationship)
                            }
                        }
                    }
                }
//                if hasBuyer {
//                    let transition = AnyTransition.move(edge: .bottom)
//                    EqualWidthVStackLayout(spacing: 10) {
//                        Button { } label: {
//                            Text("\(vm.currentBuyer.name) is buying")
//                                .font(.title2)
//                                .frame(maxWidth: .infinity)
//                        }
//                        .buttonStyle(.borderedProminent)
//                        Button {
//                        } label: {
//                            Text("Someone else is buying")
//                                .font(.title2)
//                                .frame(maxWidth: .infinity)
//                        }
//                        .buttonStyle(.bordered)
//                    }
//                    .padding()
//                    .padding(.bottom, 30)
//                    .frame(width: geo.size.width)
//                    .background(.regularMaterial)
//                    .transition(transition)
//                }
            }
            .animation(.default, value: hasBuyer)
            .navigationTitle("Who's Here?")
        }
    }
}

#Preview {
    SomeoneElseBuying(vm: ViewModel())
}
