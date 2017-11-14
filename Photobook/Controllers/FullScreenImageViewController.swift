//
//  FullScreenImageViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 13/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol FullScreenImageViewControllerDelegate: class {
    func fullScreenImageViewControllerDidUpdateAsset(asset: Asset)
}

class FullScreenImageViewController: UIViewController {
    
    @IBOutlet weak var swipeDownIndicator: UIImageView!
    @IBOutlet weak var selectedStatusImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var asset: Asset!
    var album: Album!
    weak var sourceView: UIView?
    weak var delegate: FullScreenImageViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        asset.image(size: preferredContentSize, completionHandler: { [weak welf = self] (image, _) in
            if image != nil {
                welf?.imageView.image = image
                welf?.activityIndicator.stopAnimating()
            }
        })
    }
    
    private func updateSelectedStatusIndicator(){
        selectedStatusImageView.image = SelectedAssetsManager.selectedAssets(album).contains(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }) ? UIImage(named: "Tick") : UIImage(named: "Tick-empty")
    }
    
    // Run when the user presses even more firmly to pop the preview to full screen
    func prepareForPop(){
        view.backgroundColor = .black
        
        updateSelectedStatusIndicator()
        
        selectedStatusImageView.isHidden = false
        
        guard let imageView = self.imageView ,
            let image = imageView.image
            else { return }
        
        //Constrain the image view to the image's aspect ratio and make sure there is space at the bottom for the swipe down indicator
        imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .height, relatedBy: .equal, toItem: imageView, attribute: .width, multiplier: image.size.height / image.size.width, constant: 0))
        
        view.addConstraint(NSLayoutConstraint(item: view.layoutMarginsGuide, attribute: .bottom, relatedBy: .greaterThanOrEqual, toItem: swipeDownIndicator, attribute: .bottom, multiplier: 1, constant: 17))
    }
    
    // Select or deselect the asset
    @IBAction func tapGestureRecognized(_ sender: Any) {
        var selectedAssets = SelectedAssetsManager.selectedAssets(album)
        if let index = selectedAssets.index(where: { (selectedAsset) in
            return selectedAsset.identifier == asset.identifier
        }){
            selectedAssets.remove(at: index)
        } else {
            selectedAssets.append(asset)
        }
        
        SelectedAssetsManager.setSelectedAssets(album, newSelectedAssets: selectedAssets)
        updateSelectedStatusIndicator()
        self.delegate?.fullScreenImageViewControllerDidUpdateAsset(asset: asset)
    }
    
    @IBAction func panGestureRecognized(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            UIView.animate(withDuration: 0.3, animations: {
                self.swipeDownIndicator.alpha = 0
                self.selectedStatusImageView.alpha = 0
            })
        case .changed:
            let translation = sender.translation(in: view)
            let transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            
            // As the user drags down, fade out the background and slightly scale the image
            let percentOfHalfScreenSwiped = abs(translation.y / (view.bounds.size.height / 2.0))
            view.backgroundColor = UIColor(white: 0, alpha: 1.0 - percentOfHalfScreenSwiped)
            
            let scale = 1 - 0.25 * percentOfHalfScreenSwiped
            imageView.transform = transform.scaledBy(x: scale, y: scale)
        case .ended:
            performSegue(withIdentifier: "FullScreenImageUnwindSegue", sender: nil)
        default:
            break
        }
    }
}
