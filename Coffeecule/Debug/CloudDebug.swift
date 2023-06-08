//
//  CloudDebug.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 2/3/23.
//

import Foundation
import SwiftUI
import CloudKit
//import UIKit

class CloudKitViewModel: ObservableObject {
    
    @Published var permissionStatus: Bool = false
    @Published var isSignedInToiCloud: Bool = false
    @Published var signInError: String = ""
    @Published var userName: String = ""
    @Published var familyName: String = ""
    
    init() {
        getiCloudStatus()
        requestPermission()
        fetchiCloudUserRecordID()
    }
    
    enum CloudKitError: String, LocalizedError {
        case iCloudAccountNotFound
        case iCloudAccountNotDetermined
        case iCloudAccountRestricted
        case iCloudAccountUnknown
    }
    
    func getiCloudStatus() {
        CKContainer.default().accountStatus { returnedStatus, returnedError in
            DispatchQueue.main.async {
                switch returnedStatus {
                case .available:
                    self.isSignedInToiCloud = true
                case .noAccount:
                    self.signInError = CloudKitError.iCloudAccountNotFound.rawValue
                case .couldNotDetermine:
                    self.signInError = CloudKitError.iCloudAccountNotDetermined.rawValue
                case .restricted:
                    self.signInError = CloudKitError.iCloudAccountRestricted.rawValue
                default:
                    self.signInError = CloudKitError.iCloudAccountUnknown.rawValue
                }
            }
        }
    }
    
    func requestPermission() {
        CKContainer.default().requestApplicationPermission([.userDiscoverability]) { [weak self] returnedStatus, returnedError in
            DispatchQueue.main.async {
                if returnedStatus == .granted {
                    self?.permissionStatus = true
                } else {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
            }
        }
    }
    
    func fetchiCloudUserRecordID() {
        CKContainer.default().fetchUserRecordID { returnedID, returnedError in
            if let id = returnedID {
                self.discoveriCloudUser(id: id)
            }
        }
    }
    
    func discoveriCloudUser (id: CKRecord.ID) {
        CKContainer.default().discoverUserIdentity(withUserRecordID: id) { [weak self] returnedIdentity, returnedError  in
            DispatchQueue.main.async {
                if let name =  returnedIdentity?.nameComponents?.givenName {
                    self?.userName = name
                }
                if let familyName = returnedIdentity?.nameComponents?.familyName {
                    self?.familyName = familyName
                }
            }
        }
    }
}

struct CloudView: View {
    @State var isPresented = false
    @StateObject var vm = CloudKitViewModel()
    var body: some View {
        VStack {
            Text("IS SIGNED IN: \(vm.isSignedInToiCloud.description.uppercased())")
            Text(vm.signInError)
            Text("Permission: \(vm.permissionStatus.description.uppercased())")
            Text("given NAME: \(vm.userName)")
            Text("family NAME: \(vm.familyName)")
            Button("tap me") {
                isPresented = true
            }.alert("do you want to enable cloud stuff?", isPresented: $isPresented) {
                HStack {
                    Text("yes")
                    Text("no?")
                }
            }
        }
    }
}


struct CloudView_Previews: PreviewProvider {
    static var previews: some View {
        CloudView()
    }
}
