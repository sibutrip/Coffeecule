//
//  JoinSheet.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 4/28/23.
//

import SwiftUI

struct JoinSheet: View {
    enum ViewState: Equatable {
        case loading, loaded
    }
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss: DismissAction
    
    @State var couldNotJoinCule = false
    @State var couldntCreateCule = false
    
    @State var rootUserID: String?
    @State var viewState = ViewState.loading
    
    func rootUserID() async -> String? {
        return await vm.repository.rootRecord?.recordID.recordName
    }
    
    var sortedPeople: [Person] {
        vm.relationships
            .sorted(by: { first, second in
                first.person.userID == rootUserID })
            .map { $0.person }
    }
    var body: some View {
        NavigationStack {
            if vm.state == .loading { ProgressView() } else {
                List {
                    Section("members") {
                        ForEach(sortedPeople) { person in
                            Text(person.name)
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
        .task {
            viewState = .loading
            await rootUserID = rootUserID()
            viewState = .loaded
        }
    }
}


