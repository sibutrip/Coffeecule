//
//  CustomizeCupView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/8/23.
//

import SwiftUI

struct CustomizeCupView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var vm: ViewModel
    let relationship: Relationship
    var person: Person { relationship.person }
    let columns = [
        GridItem(.flexible(minimum: 10, maximum: .infinity)),
        GridItem(.flexible(minimum: 10, maximum: .infinity))
    ]
    @State var userNotFound = false
    @Binding var selectedColor: UserColor
    @Binding var selectedMug: MugIcon
    
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                Spacer()
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(MugIcon.allCases,id: \.rawValue) { mugIcon in
                        Button {
                            selectedMug = mugIcon
                        } label: {
                            CupPickerDetail(person: person, icon: mugIcon, selectedMugIcon: $selectedMug, color: $selectedColor)
                        }
                    }
                }
                Spacer()
                HStack {
                    ForEach(UserColor.allCases,id: \.rawValue) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            ColorPickerDetail(color: color, selectedColor: $selectedColor)
                        }
                    }
                }
                Spacer()
                Spacer()
            }
            .padding(.horizontal)
            .navigationTitle("Customize Your Cup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Could not find your profile! Try restarting the app", isPresented: $userNotFound) {
            Button("Ok") { userNotFound = false }
        }
        .onDisappear {
            let relationships = vm.relationships.filter { $0.person == person }
            if relationships.count > 0 {
                let newRelationship = relationships[0]
                Task {
                    try await vm.updateInCloud(person: newRelationship.person)
                }
            }
        }
    }
    init(vm: ViewModel) {
        
        
        self.vm = vm
        let relationships = vm.relationships
            .filter { relationship in
                if let userID = vm.userID {
                    return userID == relationship.person.associatedRecord["userID"] as? String
                }
                return false
            }
        if relationships.count == 0 {
            relationship = Relationship(Person())
            _selectedColor = .constant(.purple)
            _selectedMug = .constant(.mug)
            userNotFound = true
        } else {
            var relationship = relationships[0]
            self.relationship = relationship
            
            _selectedColor = Binding {
                return vm.relationships.first { $0.person.associatedRecord["userID"] as? String == vm.userID }?.userColor ?? UserColor.purple
            } set: { newColor in
                var relationships = vm.relationships.filter { $0.person != relationship.person }
                relationship.person.setUserColor(to: newColor)
                relationships.append(relationship)
                relationships = relationships.sorted()
                vm.relationships = relationships
            }
            
            _selectedMug = Binding {
                return vm.relationships.first { $0.person.associatedRecord["userID"] as? String == vm.userID }?.mugIcon ?? .mug
            } set: { newMug in
                var relationships = vm.relationships.filter { $0.person != relationship.person }
                relationship.person.setMugIcon(to: newMug)
                relationships.append(relationship)
                relationships = relationships.sorted()
                vm.relationships = relationships
            }
        }
    }
}

#Preview {
    GeometryReader { geo in
        CustomizeCupView(vm: ViewModel())
    }
}
