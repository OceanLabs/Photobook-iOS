//
//  ImageCollectorTableViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class ImageCollectorCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var deleteView: UIVisualEffectView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    
    private(set) var isWobbling:Bool = false
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
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
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(Float.random(min: 0, max: 0.1))) {
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
    }
}
