//
//  ViewStorySegue.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 20/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class ViewStorySegue: UIStoryboardSegue {
    
    var sourceView: UIView?
    var asset: Asset?

    override func perform() {
        guard let sourceView = sourceView,
            let asset = asset,
            let navigationController = source.navigationController,
            let sourceViewSuperView = sourceView.superview,
            let destination = destination as? AssetPickerCollectionViewController
            else { source.navigationController?.pushViewController(self.destination, animated: true); return }
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.alpha = 0
        
        navigationController.view.addSubview(imageView)
        let frame = sourceViewSuperView.convert(sourceView.frame, to: navigationController.view)
        imageView.frame = frame
        
        let shadeView =  UIView()
        shadeView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        shadeView.frame = imageView.bounds
        imageView.addSubview(shadeView)
        
        
        let size = CGSize(width: source.view.frame.size.width, height: source.view.frame.size.width / AssetPickerCollectionViewController.coverAspectRatio)
        asset.image(size: size, completionHandler: {(image, _) in
            imageView.image = image
        })
        
        UIView.animate(withDuration: 0.1, animations: {
            imageView.alpha = 1
        }, completion: {(_) in
            self.source.navigationController?.pushViewController(destination, animated: true)
            
            // Need to wait a slight bit so that the nav bar can adjust its height
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01, execute: {
                UIView.animate(withDuration: 0.4, animations: {
                    imageView.frame = CGRect(x: 0, y: navigationController.navigationBar.frame.maxY, width: size.width, height: size.height)
                    shadeView.frame = imageView.bounds
                }, completion: { (_) in
                    UIView.animate(withDuration: 0.1, animations: {
                        imageView.alpha = 0
                    }, completion: { (_) in
                        imageView.removeFromSuperview()
                    })
                })
            })
        })
        
    }
    
    
}
