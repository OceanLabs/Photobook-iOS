//
//  UIImageViewExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 13/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

extension UIImageView {
    
    private struct Constants {
        static let fadeDuration = 0.2
    }
    
    
    ///  Set the image from an Asset to the imageView and fade in while doing so
    ///
    /// - Parameters:
    ///   - asset: The Asset to use to get the image from
    ///   - size: Request a specific size from the asset. If nil the imageView's frame size will be used
    ///   - validCellCheck: Called after the image has been fetched, but doesn't wait for the fade animation to complete. The completion handler returns a Bool indicating if we're allowed to continue. A typical example where it will be false is if we are in a reusable view (cell) which has been recycled.
    func setImage(from: Asset?, fadeIn: Bool = true, size: CGSize? = nil, validCellCheck:(()->(Bool))? = nil) {
        guard let asset = from else {
            image = nil
            return
        }
        
        self.alpha = 0
        let size = size ?? self.frame.size
        asset.image(size: size, loadThumbnailFirst: true, progressHandler: nil, completionHandler: { image, error in
            guard validCellCheck?() ?? true else { return }
            
            self.image = image
            UIView.animate(withDuration: fadeIn ? Constants.fadeDuration : 0, animations: {
                self.alpha = 1
            })
        })
    }
    
}
