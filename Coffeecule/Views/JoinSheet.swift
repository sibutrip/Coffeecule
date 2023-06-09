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
    
    @State var couldNotJoinCule = false
    @State var couldntCreateCule = false
    
    var sortedPeople: [Person] {
        vm.relationships
            .sorted(by: { first, second in
                first.name == Repository.shared.rootRecord!["name"] as! String })
            .map { $0.person }
    }
    var body: some View {
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
                    JoinView(vm: vm, couldNotJoinCule: $couldNotJoinCule, couldntCreateCule: $couldntCreateCule, parentDismiss: dismiss)
                }
                Button("I'm already in this coffeecule") {
                    dismiss()
                }
            }
            .navigationTitle("Join coffeecule")
        }
    }
}


