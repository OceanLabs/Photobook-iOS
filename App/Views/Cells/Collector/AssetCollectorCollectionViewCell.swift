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

class AssetCollectorCollectionViewCell: BorderedCollectionViewCell {
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var containerView: UIView! {
        didSet {
            containerView.bezierRoundedCorners(withRadius: BorderedCollectionViewCell.cornerRadius)
        }
    }
    
    private(set) var isWobbling:Bool = false
    var assetId: String?
    var isDeletingEnabled:Bool = false {
        didSet {
            if isDeletingEnabled {
                deleteView.isHidden = false
                startWobbleAnimation()
            } else {
                deleteView.isHidden = true
                endWobbleAnimation()
            }
        }
    }
    
    func setup() {
        startWobbleAnimation()
    }
    
    @IBAction func startWobbleAnimation() {
        
        let animation = CAKeyframeAnimation(keyPath: "transform")
        let wobbleAngle:CGFloat = 0.05
        let valLeft = NSValue(caTransform3D: CATransform3DMakeRotation(wobbleAngle, 0, 0, 1))
        let valRight = NSValue(caTransform3D: CATransform3DMakeRotation(-wobbleAngle, 0, 0, 1))
        animation.values = [valLeft, valRight]
        animation.autoreverses = true
        animation.duration = 0.125
        animation.repeatCount = Float.infinity
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        
        containerView.layer.removeAllAnimations()
        DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0.0 ... 0.1)) {
            self.containerView.layer.add(animation, forKey: "transform")
        }
        
        isWobbling = true
    }
    
    @IBAction func endWobbleAnimation() {
        containerView.layer.removeAllAnimations()
        
        isWobbling = false
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        isDeletingEnabled = false
        imageView.image = nil
    }
}
