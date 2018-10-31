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
        
        destination.delayCollectorAppearance = true
        
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
        
        // Add the destination view controller view to the view hierachy to animate it
        destination.setupCollector()
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
            
            destination.registerFor3DTouch()
        })
        
    }
    
    private func calculateBeginPosition() -> CGFloat {
        guard let sourceView = sourceView else { return 0 }
        
        if sourceView.frame.width < source.view.frame.width / 2 {
            // Two stories
            
            if sourceView.frame.origin.x < source.view.frame.width / 2 {
                // Left story
                return sourceView.frame.maxX - source.view.frame.width
            } else {
                // Right story
                return sourceView.frame.origin.x
            }
        }
        
        // Single Story
        return 0
    }
    
    
}
