//
//  PublicProtocols.swift
//  Photobook
//
//  Created by Jaime Landazuri on 10/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

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
