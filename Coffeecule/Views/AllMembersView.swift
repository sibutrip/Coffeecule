//
//  AllMembersView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI
import CloudKit

struct AllMembersView: View {
    @State var share: CKShare?
    @State var container: CKContainer?
    @Environment(\.editMode) var editMode
    @ObservedObject var vm: ViewModel
    @State private var userIsOwner = false
    @State private var viewingHistory = false
    @State private var customizingCup = false
    @State private var isDeletingCoffeecule = false
    @State private var isSharing = false
    @Binding var someoneElseBuying: Bool
    @Binding var isBuying: Bool
    private let columns = [
        GridItem(.flexible(minimum: 10, maximum: .infinity),spacing: 0),
        GridItem(.flexible(minimum: 10, maximum: .infinity),spacing: 0)
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
                            .disabled(editMode?.wrappedValue.isEditing ?? false)
                        }
                    }
                }
                if hasBuyer && !(editMode?.wrappedValue.isEditing ?? true) {
                    let transition = AnyTransition.move(edge: .bottom)
                    EqualWidthVStackLayout(spacing: 10) {
                        Button {
                            isBuying = true
                        } label: {
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
                if editMode?.wrappedValue.isEditing ?? false {
                    let transition = AnyTransition.move(edge: .bottom)
                    EqualWidthVStackLayout(spacing: 10) {
                        Button {
                            Task {
                                try await vm.shareCoffeecule()
                                if let share = await vm.repository.rootShare {
                                    self.share = share
                                    self.container = Repository.container
                                    isSharing = true
                                }
                            }
                        } label: {
                            Label("Add New Person", systemImage: "person.crop.circle.fill.badge.plus")
                                .font(.title2)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        if userIsOwner {
                            Button {
                                isDeletingCoffeecule = true
                            } label: {
                                Label("Delete Coffeecule", systemImage: "trash")
                                    .font(.title2)
                                    .frame(maxWidth: .infinity)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.bordered)
                        }
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
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
        }
        .sheet(isPresented: $viewingHistory) {
            HistoryView(vm: vm)
        }
        .sheet(isPresented: $customizingCup) {
            CustomizeCupView(vm: vm)
        }
        .alert("Are you sure you want to delete your Coffeecule? This action is not reversable.", isPresented: $isDeletingCoffeecule) {
            HStack {
                Button("Yes", role: .destructive) {
                    Task {
                        do {
                            try await vm.deleteCoffeecule()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
                Button("No", role: .cancel) {
                    isDeletingCoffeecule = false
                }
                
            }
        }
        .sheet(isPresented: $isSharing) {
            if let share = share, let container = container {
                CloudSharingView(share: share, container: container)
            } else {
                EmptyView()
            }
        }
        .task {
            userIsOwner = await vm.viewerIsOwner
        }
    }
    init(vm: ViewModel, someoneElseBuying: Binding<Bool>, isBuying: Binding<Bool>) {
        self.vm = vm
        _someoneElseBuying = someoneElseBuying
        _isBuying = isBuying
    }
}

#Preview {
    AllMembersView(vm: ViewModel(), someoneElseBuying: .constant(false), isBuying: .constant(false))
}
