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
import Photobook

protocol FullScreenImageViewControllerDelegate: class {
    func previewDidUpdate(asset: PhotobookAsset)
    func sourceView(for asset: PhotobookAsset) -> UIView?
}

class FullScreenImageViewController: UIViewController {
    
    @IBOutlet private weak var swipeDownIndicator: UIImageView!
    @IBOutlet private weak var selectedStatusImageView: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    var asset: PhotobookAsset!
    weak var delegate: FullScreenImageViewControllerDelegate?
    var selectedAssetsManager: SelectedAssetsManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        PhotobookSDK.shared.cachedImage(for: asset, size: preferredContentSize) { [weak welf = self] (image, _) in
            if image != nil {
                welf?.imageView.image = image
                welf?.activityIndicator.stopAnimating()
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    private func updateSelectedStatusIndicator(){
        let selected = selectedAssetsManager?.isSelected(asset) ?? false
        selectedStatusImageView.image = selected ? UIImage(named: "Tick") : UIImage(named: "Tick-empty")
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
        guard let selectedAssetsManager = selectedAssetsManager else { return }
        guard selectedAssetsManager.toggleSelected(asset) else {
            let alertController = UIAlertController(title: NSLocalizedString("ImagePicker/TooManyPicturesAlertTitle", value: "Too many pictures", comment: "Alert title informing the user that they have reached the maximum number of images"), message: NSLocalizedString("ImagePicker/TooManyPicturesAlertMessage", value: "Your photo book cannot contain more than \(PhotobookSDK.shared.maximumAllowedPhotos)", comment: "Alert message informing the user that they have reached the maximum number of images"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonLocalizedStrings.alertOK, style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
            return
        }
        updateSelectedStatusIndicator()
        
        self.delegate?.previewDidUpdate(asset: asset)
    }
    
    @IBAction func panGestureRecognized(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            delegate?.sourceView(for: asset)?.isHidden = true
            UIView.animate(withDuration: 0.3, animations: {
                self.swipeDownIndicator.alpha = 0
                self.selectedStatusImageView.alpha = 0
            })
        case .changed:
            let translation = sender.translation(in: view)
            let transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            
            // As the user drags away from the center, fade out the background and slightly scale the image
            let distance = sqrt(translation.x * translation.x + translation.y * translation.y)
            let percentOfHalfScreenSwiped = abs(distance / (view.bounds.size.height / 2.0))
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
