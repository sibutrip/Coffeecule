//
//  HistoryView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 9/14/23.
//

import SwiftUI

struct HistoryView: View {
    enum HistoryType: String {
        case Transactions, Relationships
    }
    @State var historyType: HistoryType = .Transactions
    @ObservedObject var vm: ViewModel
    var body: some View {
        NavigationStack {
            VStack {
                Picker("History", selection: $historyType) {
                    Text("Transactions").tag(HistoryType.Transactions)
                    Text("Relationships").tag(HistoryType.Relationships)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                Spacer()
                switch historyType {
                case .Transactions:
                    TransactionHistory(vm: vm)
                case .Relationships:
                    RelationshipWeb(vm: vm)
                }
            }
            .navigationTitle(historyType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    HistoryView(vm: ViewModel())
}
