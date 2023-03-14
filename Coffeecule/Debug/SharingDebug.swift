//
//  SharingDebug.swift
//  Coffeecule
//
//  Created by Cory Tripathy on 3/3/23.
//

import Foundation
import SwiftUI
import CloudKit

struct SharingView: View {
    
    @StateObject var vm = ViewModel(readWriter: ReadWrite.shared)
    
    @State var sharing = false
    var body: some View {
        NavigationView {
            List {
                Text("woo")
            }
            .toolbar {
                Button {
                    Task {
                        sharing = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
            .navigationTitle("woo")
        }
        .sheet(isPresented: $sharing) {
            CloudSharingView(share: Repository.shared.ckShare!, record: Repository.shared.rootRecord!)
        }
    }
}
