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
        imageView.cornerRadius = 4
        
        navigationController.view.addSubview(imageView)
        let frame = sourceViewSuperView.convert(sourceView.frame, to: navigationController.view)
        imageView.frame = frame
        
        let shadeView =  UIView()
        shadeView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        shadeView.frame = imageView.bounds
        imageView.addSubview(shadeView)
        
        destination.shouldFadeInImages = false
        
        let size = CGSize(width: source.view.frame.size.width, height: source.view.frame.size.width / AssetPickerCollectionViewController.coverAspectRatio)
        asset.image(size: size, completionHandler: {(image, _) in
            imageView.image = image
        })
        
        // Let's animate all the views! 🙋‍♂️
        UIView.animate(withDuration: 0.1, animations: {
            // Creates the effect that the text fades out
            imageView.alpha = 1
        }, completion: {(_) in
            // Hide the sourceView so that it appears to transform itself and it leaves an empty space where it was
            sourceView.alpha = 0
            
            // Snapshot the source vc to use in the animation
            let sourceSnapShot = self.source.view.snapshotView(afterScreenUpdates: true)
            if sourceSnapShot != nil{
                navigationController.view.insertSubview(sourceSnapShot!, belowSubview: navigationController.navigationBar)
            }
            navigationController.pushViewController(destination, animated: false)
            
            // Need to wait a slight bit because push seems to happen asynchronously. Also because we want the dest vc to load its high quality thumbnails otherwise there's an unpleasant effect where they all seem to update at once. The delay is imperceptible.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.05, execute: {
                
                // Snapshot the destination vc to animate, so that we avoid scaling the live vc. It starts from the frame of the sourceView
                let destSnapShot = destination.view.snapshotView(afterScreenUpdates: true)
                destSnapShot?.alpha = 0
                destSnapShot?.frame = imageView.frame
                if destSnapShot != nil{
                    navigationController.view.insertSubview(destSnapShot!, belowSubview: navigationController.navigationBar)
                }
                destination.shouldFadeInImages = true
                
                UIView.animate(withDuration: 0.45, animations: {
                    
                    // Animate the banner image and dest vc to their final frame, as well as fade in the dest vc
                    imageView.frame = CGRect(x: 0, y: navigationController.navigationBar.frame.maxY, width: size.width, height: size.height)
                    shadeView.frame = imageView.bounds
                    imageView.layer.cornerRadius = 0
                    destSnapShot?.frame = destination.view.frame
                    destSnapShot?.alpha = 1
                }, completion: { (_) in
                    
                    // Do away with the illusions
                    sourceSnapShot?.removeFromSuperview()
                    destSnapShot?.removeFromSuperview()
                    sourceView.alpha = 1
                    
                    UIView.animate(withDuration: 0.1, animations: {
                        (destination.tabBarController?.tabBar as? PhotobookTabBar)?.isBackgroundHidden = true
                        
                        // Creates the effect that the text fades in
                        imageView.alpha = 0
                    }, completion: { (_) in
                        imageView.removeFromSuperview()
                    })
                })
            })
        })
        
    }
    
    
}
