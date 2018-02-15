//
//  AssetCollectorCollectionViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
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
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        
        containerView.layer.removeAllAnimations()
        DispatchQueue.main.asyncAfter(deadline: .now() + Random.double(min: 0, max: 0.1)) {
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
