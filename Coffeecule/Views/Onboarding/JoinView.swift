//
//  JoinView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 6/7/23.
//

import SwiftUI

struct JoinView: View {
    @ObservedObject var vm: ViewModel
    
    @Binding var couldNotJoinCule: Bool
    @Binding var couldntCreateCule: Bool
    @Binding var customizingCup: Bool
    @State private var isLoading = false
    var parentDismiss: DismissAction? = nil
    
    @Environment(\.dismiss) var dismiss
    
    
    var body: some View {
        List {
            TextField("join as...", text: $vm.participantName)
            Button("join") {
                Task {
                    isLoading = true
                    do {
                        try await vm.joinCoffeecule()
                        switch vm.state {
                        case .loading:
                            fallthrough
                        case .loaded:
                            fallthrough
                        case .noPermission:
                            couldNotJoinCule = true
                        case .nameFieldEmpty:
                            couldNotJoinCule = true
                        case .nameAlreadyExists:
                            couldNotJoinCule = true
                        case .noShareFound:
                            couldNotJoinCule = true
                        case .noSharedContainerFound:
                            couldNotJoinCule = true
                        case .culeAlreadyExists:
                            couldNotJoinCule = true
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                    isLoading = false
                    vm.participantName.removeAll()
                    guard let parentDismiss = parentDismiss else {
                        dismiss()
                        return
                    }
                    parentDismiss()
                    customizingCup = true
                }
            }
            .disabled(isLoading)
        }
        .navigationTitle(Title.activeTitle)
        .overlay {
            if vm.state == .loading {
                ProgressView()
            }
        }
    }
}

//struct JoinView_Previews: PreviewProvider {
//    static var previews: some View {
//        JoinView()
//    }
//}
