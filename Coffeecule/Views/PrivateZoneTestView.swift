//
//  PrivateZoneTestView.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 1/13/23.
//

import SwiftUI

struct PrivateZoneTestView: View {
    @StateObject var vm = ViewModel()
    var body: some View {
        Button {
            Task {
                try await vm.uploadTransaction(buyerName:"tariq", receiverName:"cory")
            }
        } label: {
            Text("upload Transactions")
        }.onAppear {
            Task {
                try await vm.initialize()
            }
        }
    }
}

struct PrivateZoneTestView_Previews: PreviewProvider {
    static var previews: some View {
        PrivateZoneTestView()
    }
}
