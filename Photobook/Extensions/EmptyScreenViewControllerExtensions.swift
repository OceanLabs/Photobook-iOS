//
//  EmptyScreenViewControllerExtensions.swift
//  Photobook
//
//  Created by Jaime Landazuri on 12/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

extension EmptyScreenViewController {
    
    private struct Constants {
        static let permissionsTitle = NSLocalizedString("Controllers/EmptyScreenViewController/PermissionDeniedTitle",
                                                        value: "Permissions Required",
                                                        comment: "Title shown when the photo library access has been disabled")
        static let permissionsMessage = NSLocalizedString("Controllers/EmptyScreenViewController/PermissionDeniedMessage",
                                                          value: "Photo access has been restricted, but it's needed to create beautiful photo books.\nYou can turn it back on in the system settings",
                                                          comment: "Message shown when the photo library access has been disabled")
        static let permissionsButtonTitle = NSLocalizedString("Controllers/StoriesviewController/PermissionDeniedSettingsButton",
                                                              value: "Open Settings",
                                                              comment: "Button title to direct the user to the app permissions screen in the phone settings")
    }
    
    func showGalleryPermissionsScreen() {
        self.show(message: Constants.permissionsMessage, title: Constants.permissionsTitle, buttonTitle: Constants.permissionsButtonTitle, buttonAction: {
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
            }
        })
    }
    
    func showErrorScreen(error: Error) {
        if error as? LibraryError == .accessDenied {
            showGalleryPermissionsScreen()
        } else {
            show(message: error.localizedDescription)
        }
    }
}
