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
        let contentView = ContentView().environmentObject(AppAccess(accessedFromShare: false))
        
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
        let container = CKContainer(identifier: Repository.container.containerIdentifier!)
        let operation = CKAcceptSharesOperation(shareMetadatas: [cloudKitShareMetadata])
        
        debugPrint("Accepting CloudKit Share with metadata: \(cloudKitShareMetadata)")
        
        operation.perShareResultBlock = { metadata, result in
            let shareRecordType = metadata.share.recordType
            
            switch result {
            case .failure(let error):
                debugPrint("Error accepting share: \(error)")
                
            case .success:
                debugPrint("Accepted CloudKit share with type: \(shareRecordType)")
            }
        }
        
        operation.acceptSharesResultBlock = { result in
            if case .failure(let error) = result {
                debugPrint("Error accepting CloudKit Share: \(error)")
            }
        }
        operation.qualityOfService = .utility
        container.add(operation)
        
        
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UIHostingController(rootView: ContentView().environmentObject(AppAccess(accessedFromShare: true)))
        
        self.window = window
        window.makeKeyAndVisible()
        
        // show invite from "person" and then show the members in the coffeecule. then there's the add your name and join. this is a sheet over the "Create screen"
    }
}
