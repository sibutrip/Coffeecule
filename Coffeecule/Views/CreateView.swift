//
//  CreateView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 6/7/23.
//

import SwiftUI

struct CreateView: View {
    @ObservedObject var vm: ViewModel
    
    @Binding var couldNotJoinCule: Bool
    @Binding var couldntCreateCule: Bool
    @State private var isLoading = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        List {
            TextField("create as...", text: $vm.participantName)
                Button("create") {
                    Task {
                        isLoading = true
                        do {
                            try await vm.createCoffeecule()
                            switch vm.state {
                            case .loading:
                                return
                            case .loaded:
                                couldNotJoinCule = true
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
                        dismiss()
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

//struct CreateView_Previews: PreviewProvider {
//    static var previews: some View {
//        CreateView(vm: ViewModel())
//    }
//}
