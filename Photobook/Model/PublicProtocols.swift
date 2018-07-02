//
//  PublicProtocols.swift
//  Photobook
//
//  Created by Jaime Landazuri on 10/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

/// Dismiss delegate
@objc public protocol DismissDelegate {
    /// Called when a view controller is ready to be dismissed
    ///
    /// - Parameter viewController: The view controller that wants to be dismissed. If the photo book was presente modally, this will be a UINavigationController.
    @objc optional func wantsToDismiss(_ viewController: UIViewController)
}

/// PhotobookViewController delegate
@objc public protocol PhotobookDelegate: DismissDelegate {
    
    /// Custom photo picker
    @objc optional var assetPickerViewController: PhotobookAssetPicker & UIViewController { get }
}

/// Conforming classes can be notified when PhotobookAssets are added by a custom photo picker
@objc public protocol AssetCollectorAddingDelegate: class {
    func didFinishAdding(_ assets: [PhotobookAsset]?)
}

extension AssetCollectorAddingDelegate {
    func didFinishAddingAssets() {
        didFinishAdding(nil)
    }
}

/// Protocol custom photo pickers must conform to to be used with photo books
@objc public protocol PhotobookAssetPicker where Self: UIViewController {
    weak var addingDelegate: AssetCollectorAddingDelegate? { get set }
}

/// Base protocol for photobook assets
@objc public protocol PhotobookAsset {}
