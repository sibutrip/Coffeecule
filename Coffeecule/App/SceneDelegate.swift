//
//  SceneDelegate.swift
//  (cloudkit-samples) Zone Sharing
//

import UIKit
import SwiftUI
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let cloudShareMetadata = connectionOptions.cloudKitShareMetadata
        let accessedFromShare = cloudShareMetadata != nil ? true : false
        Repository.shareMetaData = cloudShareMetadata
        let contentView = ContentView().environmentObject(AppAccess(accessedFromShare: accessedFromShare))
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
    
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        
        guard cloudKitShareMetadata.containerIdentifier == Repository.container.containerIdentifier else {
            print("Shared container identifier \(cloudKitShareMetadata.containerIdentifier) did not match known identifier.")
            return
        }
        
        // Create an operation to accept the share, running in the app's CKContainer.
//        let container = CKContainer(identifier: Repository.container.containerIdentifier!)
//        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        Repository.shareMetaData = cloudKitShareMetadata
        
        debugPrint("Accepting CloudKit Share with metadata: \(cloudKitShareMetadata)")
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView()
            .environmentObject(AppAccess(accessedFromShare: true)))
        self.window = window
        window.makeKeyAndVisible()
        
    }
}
