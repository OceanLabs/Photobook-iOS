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
    var coverImage: UIImage?
    var sourceLabelsContainerView: UIView?

    override func perform() {
        guard let sourceView = sourceView,
            let navigationController = source.navigationController,
            let sourceViewSuperView = sourceView.superview,
            let destination = destination as? AssetPickerCollectionViewController
            else { source.navigationController?.pushViewController(self.destination, animated: true); return }
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.cornerRadius = 4
        
        navigationController.view.addSubview(imageView)
        let frame = sourceViewSuperView.convert(sourceView.frame, to: navigationController.view)
        imageView.frame = frame
        
        let shadeView =  UIView()
        shadeView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        shadeView.frame = imageView.bounds
        imageView.addSubview(shadeView)
        
        imageView.image = coverImage
        
        // Hide the sourceView so that it appears to transform itself and it leaves an empty space where it was
        sourceView.alpha = 0
        
        // Snapshot the source vc to use in the animation
        let sourceSnapShot = self.source.view.snapshotView(afterScreenUpdates: true)
        if sourceSnapShot != nil{
            navigationController.view.insertSubview(sourceSnapShot!, belowSubview: navigationController.navigationBar)
        }
        
        destination.view.frame = CGRect(x: calculateBeginPosition(), y: imageView.frame.origin.y, width: source.view.frame.width, height: source.view.frame.height)
        destination.view.alpha = 0
        navigationController.view.insertSubview(destination.view, belowSubview: navigationController.navigationBar)
        
        // Add label snapshots that we'll be crossfading during the animation
        let sourceLabelsContainerSnapShot = sourceLabelsContainerView?.snapshotView(afterScreenUpdates: true)
        if  sourceLabelsContainerSnapShot != nil {
            imageView.addSubview(sourceLabelsContainerSnapShot!)
            sourceLabelsContainerSnapShot?.center = CGPoint(x: imageView.frame.width/2, y: imageView.frame.height/2)
            sourceLabelsContainerSnapShot?.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        }
        
        let destinationLabelsContainerSnapshot = destination.coverImageLabelsContainerView()?.snapshotView(afterScreenUpdates: true)
        if  destinationLabelsContainerSnapshot != nil{
            destinationLabelsContainerSnapshot?.alpha = 0
            imageView.addSubview(destinationLabelsContainerSnapshot!)
            destinationLabelsContainerSnapshot?.center = CGPoint(x: imageView.frame.width/2, y: imageView.frame.height/2)
            destinationLabelsContainerSnapshot?.autoresizingMask = [.flexibleBottomMargin, .flexibleTopMargin, .flexibleLeftMargin, .flexibleRightMargin]
        }
        
        // Push a dummy view controller so that the nav bar changes height
        let dummyViewController = UIViewController()
        dummyViewController.view.backgroundColor = .white
        if #available(iOS 11.0, *) {
            dummyViewController.navigationItem.largeTitleDisplayMode = .never
        }
        navigationController.pushViewController(dummyViewController, animated: false)
        
        UIView.animate(withDuration: 0.45, delay: 0, options: [.curveEaseInOut], animations: {
            
            // Animate the banner image and dest vc to their final frame, as well as fade in the dest vc
            let size = CGSize(width: self.source.view.frame.size.width, height: self.source.view.frame.size.width / AssetPickerCollectionViewController.coverAspectRatio)
            imageView.frame = CGRect(x: 0, y: navigationController.navigationBar.frame.maxY, width: size.width, height: size.height)
            shadeView.frame = imageView.bounds
            imageView.layer.cornerRadius = 0
            destination.view.frame.origin = imageView.frame.origin
            destination.view.alpha = 1
            
            sourceLabelsContainerSnapShot?.alpha = 0
            destinationLabelsContainerSnapshot?.alpha = 1
            
        }, completion: { (_) in
            sourceSnapShot?.removeFromSuperview()
            sourceView.alpha = 1
            
            var navigationStack = navigationController.viewControllers
            navigationStack.removeLast()
            navigationStack.append(destination)
            navigationController.setViewControllers(navigationStack, animated: false)
            imageView.removeFromSuperview()
        })
        
    }
    
    private func calculateBeginPosition() -> CGFloat {
        guard let sourceView = sourceView else { return 0 }
        
        if sourceView.frame.width < source.view.frame.width / 2 {
            // Two stories
            
            if sourceView.frame.origin.x < source.view.frame.width / 2 {
                // Left story
                return sourceView.frame.origin.x + sourceView.frame.width - source.view.frame.width
            } else {
                // Right story
                return sourceView.frame.origin.x
            }
        }
        
        // Single Story
        return 0
    }
    
    
}
