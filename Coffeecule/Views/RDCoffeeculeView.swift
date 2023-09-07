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
    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                VStack(spacing: 0) {
                    ScrollView {
                        LazyVGrid(columns: columns) {
                            ForEach(vm.relationships) { relationship in
                                Circle()
                                    .foregroundStyle(.cyan)
                                    .overlay {
                                        Text(relationship.name)
                                    }
                                Circle()
                                    .foregroundStyle(.cyan)
                                    .overlay {
                                        Text(relationship.name)
                                    }
                                Circle()
                                    .foregroundStyle(.cyan)
                                    .overlay {
                                        Text(relationship.name)
                                    }
                            }
                        }
                    }
                    EqualWidthVStackLayout(spacing: 10) {
                        Button { } label: {
                            Text("Cory is buying")
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
                }
                .navigationTitle("Who's Here?")
                .toolbar {
                    ToolbarItem {
                        Button{
                            //
                        } label: {
                            Label("Transaction History", systemImage: "dollarsign.arrow.circlepath")
                        }
                    }
                }
            }
        }
    }
    init(vm: ViewModel, geo: GeometryProxy) {
        self.vm = vm
        let maxColumnWidth = geo.size.width / 4
        columns = [
            GridItem(.flexible(minimum: 10, maximum: maxColumnWidth)),
            GridItem(.flexible(minimum: 10, maximum: maxColumnWidth))
        ]
    }
}
