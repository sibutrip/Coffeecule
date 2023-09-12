//
//  HistoryView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 8/24/23.
//

import Foundation
import SwiftUI

struct HistoryView: View {
    @State var isLoading = true
    @ObservedObject var vm: ViewModel
    @State var datesAndTransactions: [Date: [Transaction]] = [:]
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else {
                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Text("Transaction History")
                                .font(.headline)
                                .padding(.bottom)
                            HStack {
                                Text("Receiver")
                                    .foregroundStyle(Color.blue)
                                Spacer()
                                Text("Buyer")
                                    .foregroundStyle(Color.red)
                            }
                            .overlay { Image(systemName: "arrow.left") }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .padding(.horizontal, 50)
                        .background {
                            Color("ListBackground")
                        }
                        if datesAndTransactions.isEmpty {
                            Text("No previous transactions. Try to buy a coffee first!")
                                .padding(.horizontal)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .ignoresSafeArea()
                                .background {
                                    Color("ListBackground")
                                }
                        } else {
                            List {
                                ForEach(datesAndTransactions.keys.sorted(by: { $0 > $1 }), id: \.self) { date in
                                    let transactions = datesAndTransactions[date] ?? []
                                    if !transactions.isEmpty {
                                        Section(date.formatted(date: .abbreviated, time: .omitted)) {
                                            ForEach(transactions) { transaction in
                                                HStack {
                                                    Text(transaction.receiverName)
                                                    Spacer()
                                                    Text(transaction.buyerName)
                                                }
                                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                                    Button {
                                                        withAnimation {
                                                            datesAndTransactions[date] = datesAndTransactions[date]?
                                                                .filter { $0.id != transaction.id }
                                                        }
                                                        Task {
                                                            try await vm.remove(transaction: transaction)
                                                        }
                                                    } label: {
                                                        Label("Trash", systemImage: "trash")
                                                    }
                                                    .tint(.red)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .refreshable {
                                Task {
                                    #warning("put need at least 2 fo buy")
                                    await vm.refreshData()
                                    let transactions = await vm.repository.transactions?.sorted { $0.creationDate! > $1.roundedDate! } ?? []
                                    let datesAndTransactions = Dictionary(grouping: transactions) { $0.roundedDate! }
                                    self.datesAndTransactions = datesAndTransactions
                                    //            transactions.forEach { print($0.buyerName) }
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            isLoading = true
            let transactions = await vm.repository.transactions?.sorted { $0.creationDate! > $1.roundedDate! } ?? []
            let datesAndTransactions = Dictionary(grouping: transactions) { $0.roundedDate! }
            self.datesAndTransactions = datesAndTransactions
            //            transactions.forEach { print($0.buyerName) }
            isLoading = false
        }
    }
}
