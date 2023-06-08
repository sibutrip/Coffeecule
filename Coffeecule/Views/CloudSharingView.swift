//
//  CloudSharingView.swift
//  (cloudkit-samples) Sharing
//

import Foundation
import SwiftUI
import UIKit
import CloudKit

/// This struct wraps a `UICloudSharingController` for use in SwiftUI.
struct CloudSharingView: UIViewControllerRepresentable {

    // MARK: - Properties

    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var repo: PersonService
    
    // MARK: - UIViewControllerRepresentable
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let sharingController = UICloudSharingController(share: repo.rootShare!, container: Repository.shared.container)
            sharingController.availablePermissions = [.allowReadWrite, .allowPrivate]
            sharingController.delegate = context.coordinator
            sharingController.modalPresentationStyle = .formSheet
            return sharingController
    }

    func makeCoordinator() -> CloudSharingView.Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            debugPrint("Error saving share: \(error)")
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            "Sharing Example"
        }
    }
}