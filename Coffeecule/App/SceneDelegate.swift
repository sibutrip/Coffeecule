//
//  SceneDelegate.swift
//  (cloudkit-samples) Zone Sharing
//

import UIKit
import SwiftUI
import CloudKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var userDidAcceptInvite = false

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = ContentView()
        
        if self.userDidAcceptInvite {
            contentView.vm.hasCoffeecule = true
        }

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata) {
        
        guard cloudKitShareMetadata.containerIdentifier == Repository.shared.container.containerIdentifier else {
            print("Shared container identifier \(cloudKitShareMetadata.containerIdentifier) did not match known identifier.")
            return
        }

        // Create an operation to accept the share, running in the app's CKContainer.
        let container = CKContainer(identifier: Repository.shared.container.containerIdentifier!)
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
        self.userDidAcceptInvite = true
    }
}