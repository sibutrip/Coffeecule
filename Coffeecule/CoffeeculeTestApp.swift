//
//  CoffeeculeTestApp.swift
//  CoffeeculeTest
//
//  Created by Cory Tripathy on 1/27/23.
//

import SwiftUI
import CloudKit

@main
struct CoffeeculeTestApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            //            CloudView()
                        ContentView()
//            CoffeeculeView(vm: ViewModel(readWriter: ReadWrite.shared))
//            SharingView()
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {

        let acceptShareOperation: CKAcceptSharesOperation =
        CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])

        acceptShareOperation.qualityOfService = .userInteractive
        acceptShareOperation.perShareResultBlock = { meta, result in
            print("share was accepted?")
        }
        acceptShareOperation.acceptSharesResultBlock = { result in
            /// Send your user to where they need to go in your app
        }

        CKContainer(identifier: cloudKitShareMetadata.containerIdentifier).add(acceptShareOperation)
    }
}
