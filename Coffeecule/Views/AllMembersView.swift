//
//  AllMembersView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/11/23.
//

import SwiftUI
import CloudKit
import Charts

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
    
    @State var dragDistance: CGFloat? = nil
    @State private var buyButtonsSize: CGSize = .zero
    
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
                    ChildSizeReader(size: $buyButtonsSize) {
                        VStack {
                            RoundedRectangle(cornerRadius: 10)
                                .frame(width: geo.size.width / 8, height: 8)
                                .foregroundStyle(.gray)
                                .padding(.top, 10)
                                .padding(.bottom, 5)
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
                        }
                        .frame(width: geo.size.width)
                    }
                    .padding(.bottom, 40 + (dragDistance ?? 0) )
                    .overlay {
                        VStack {
                            Spacer()
                            relationshipWebChart
                                .frame(height: (dragDistance ?? 0))
//                                .offset(y: 40)
                            
                            //                            .frame(height: dragDistance ?? 0 )
                            //                            .offset(y: dragDistance ?? 0)
                        }
                    }
                    .background(.regularMaterial)
                    .transition(transition)
                    .highPriorityGesture(
                        DragGesture()
                            .onChanged { newValue in
                                dragDistance = -newValue.translation.height + (dragDistance ?? 0)
                            }
                            .onEnded { newValue in
                                withAnimation {
                                    if (dragDistance ?? 0) + -newValue.predictedEndLocation.y > geo.size.height * (1/4) {
                                        dragDistance = geo.size.height / 2
                                    } else {
                                        dragDistance = 0
                                    }
                                }
                            }
                    )
                    .onTapGesture {
                        withAnimation {
                            if dragDistance == 0 {
                                dragDistance = geo.size.height / 2
                            } else {
                                dragDistance = 0
                            }
                        }
                    }
                    .onDisappear {
                        dragDistance = 0
                    }
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
            TransactionHistory(vm: vm)
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

extension AllMembersView {
    var relationshipWebChart: some View {
//        Section {
            chart(vm.displayedDebts)
//                .frame(height: 100)
                .animation(.default, value: vm.presentPeopleCount)
//                .onAppear { withAnimation { chartScale = 1 } }
//                .onDisappear { withAnimation { chartScale = 0 } }
//        }
    }
    func chart(_ debt: [Person : Int])  -> some View {
        let displayedDebts = debt
        if #available(iOS 16, *) {
            return Chart(displayedDebts.keys.sorted(), id: \.self) {
                BarMark(
                    x: .value("person", $0.name),
                    y: .value("cups bought", displayedDebts[$0] ?? 10)
                ).foregroundStyle(displayedDebts[$0] ?? 0 > 0 ? .blue : .red)
            }
        } else {
            return EmptyView()
        }
    }
}
