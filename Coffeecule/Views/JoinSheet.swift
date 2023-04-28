//
//  JoinSheet.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/28/23.
//

import SwiftUI

struct JoinSheet: View {
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss: DismissAction
    @Binding var isLoading: Bool
    var sortedPeople: [Person] {
        vm.people.sorted(by: { first, second in
            first.name == vm.personService.rootRecord!["name"] as? String ?? "" })
    }
    var body: some View {
        if isLoading {
            ProgressView()
        } else {
            NavigationStack {
                List {
                    Section("members") {
                        ForEach(0..<sortedPeople.count, id: \.self) { index in
                            if index == 0 {
                                HStack {
                                    Text(sortedPeople[index].name)
                                    Text("owner")
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text(sortedPeople[index].name)
                            }
                        }
                    }
                    NavigationLink("join as new member") {
                        JoinView(vm: vm)
                    }
                    Button("I'm already in this coffeecule") {
                        dismiss()
                    }
                }
                .navigationTitle("Join coffeecule")
            }
        }
    }
}


