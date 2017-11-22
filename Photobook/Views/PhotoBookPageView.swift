//
//  PhotoBookPageView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

enum AspectRatio: CGFloat{
    case landscape = 1.777777778
    case portrait = 0.5625
    case square = 1.0
}

class PhotoBookPageView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak private var imageView: UIImageView!
    private var imageViewAspectRatioConstraint: NSLayoutConstraint?
    
    
    /// By default the aspect ratio of the image view will use the aspect ratio of the image. This overrides that.
    var aspectRatioOverride: AspectRatio? {
        didSet{
            guard let aspectRatioOverride = aspectRatioOverride else { return }
            aspectRatio = aspectRatioOverride
        }
    }
    
    private var aspectRatio: AspectRatio = .landscape {
        didSet{
            if let imageViewAspectRatioConstraint = imageViewAspectRatioConstraint{
                guard oldValue != aspectRatio else { return }
                imageView.removeConstraint(imageViewAspectRatioConstraint)
            }
            imageViewAspectRatioConstraint = NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: aspectRatio.rawValue, constant: 0)
            imageView.addConstraint(imageViewAspectRatioConstraint!)
        }
    }
    
    var image: UIImage? {
        get{
            return imageView.image
        }
        set(newImage){
            imageView.image = newImage
            
            guard aspectRatioOverride == nil, let newImage = newImage else { return }
            let imageAspectRatio = newImage.size.width / newImage.size.height
            if imageAspectRatio == 1{
                aspectRatio = .square
            }
            aspectRatio = imageAspectRatio > 1 ? .landscape : .portrait
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup(){
        Bundle.main.loadNibNamed("PhotoBookPageView", owner: self, options: nil)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(contentView)
    }

}
