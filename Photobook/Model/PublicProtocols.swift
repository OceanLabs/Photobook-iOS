//
//  PublicProtocols.swift
//  Photobook
//
//  Created by Jaime Landazuri on 10/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

public typealias PhotobookAssetPickerController = PhotobookAssetPicker & UIViewController

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
    @objc optional func assetPickerViewController() -> PhotobookAssetPickerController
    
    /// Whether the picker should animate its presentation and dismissal
    @objc optional var shouldAnimateAssetPicker: Bool { get }
}

/// Conforming classes can be notified when PhotobookAssets are added by a custom photo picker
@objc public protocol PhotobookAssetAddingDelegate: class {
    @objc func didFinishAdding(_ photobookAssets: [PhotobookAsset]?)
}

/// Protocol custom photo pickers must conform to to be used with photo books
@objc public protocol PhotobookAssetPicker where Self: UIViewController {
    weak var addingDelegate: PhotobookAssetAddingDelegate? { get set }
}
