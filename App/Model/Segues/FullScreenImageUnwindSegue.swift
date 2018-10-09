//
//  FullScreenImageUnwindSegue.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 14/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class FullScreenImageUnwindSegue: UIStoryboardSegue {

    override func perform() {
        guard let source = source as? FullScreenImageViewController,
            let sourceView = source.delegate?.sourceView(for: source.asset),
            let sourceViewSuperview = sourceView.superview
            else {
                self.source.dismiss(animated: true, completion: nil)
                return
        }
        
        sourceView.isHidden = true
        
        let imageView = source.imageView!
        
        //Add a copy image view to animate back to the thumbnail
        let animationImageView = UIImageView(image: imageView.image)
        animationImageView.frame = imageView.frame
        animationImageView.contentMode = .scaleAspectFill
        animationImageView.clipsToBounds = true
        source.view.addSubview(animationImageView)
        imageView.isHidden = true
        
        let endFrame = (sourceViewSuperview.convert(sourceView.frame, to: source.view))
        
        UIView.animate(withDuration: 0.25, animations: {
            animationImageView.frame = endFrame
            source.view.backgroundColor = UIColor.clear
        }, completion:{(finished: Bool) in
            sourceView.isHidden = false
            source.dismiss(animated: false, completion: nil)
        })
        
    }
    
}
