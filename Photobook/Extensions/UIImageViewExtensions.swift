//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

extension UIImageView {
    
    private struct Constants {
        static let fadeDuration = 0.2
    }
    
    ///  Set the image from an Asset to the imageView and fade in while doing so
    ///
    /// - Parameters:
    ///   - asset: The asset to use to get the image from
    ///   - size: Request a specific size from the asset. If nil the imageView's frame size will be used
    ///   - validCellCheck: Called after the image has been fetched, but doesn't wait for the fade animation to complete. The completion handler returns a Bool indicating if we're allowed to continue. A typical example where it will be false is if we are in a reusable view (cell) which has been recycled.
    func setImage(from asset: Asset?, fadeIn: Bool = true, size: CGSize? = nil, validCellCheck:(()->(Bool))? = nil) {
        guard let asset = asset else {
            image = nil
            return
        }
        
        self.alpha = 0
        let size = size ?? self.frame.size
        AssetLoadingManager.shared.image(for: asset, size: size, loadThumbnailFirst: true, progressHandler: nil, completionHandler: { image, error in
            guard validCellCheck?() ?? true else { return }
            
            self.image = image
            UIView.animate(withDuration: fadeIn ? Constants.fadeDuration : 0, animations: {
                self.alpha = 1
            })
        })
    }
    
}
