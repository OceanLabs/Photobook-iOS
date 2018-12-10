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
import FBSDKLoginKit

class FacebookLandingViewController: UIViewController {
    
    @IBOutlet weak var facebookLogoCenterYConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // If we are logged in show the Facebook album picker
        if FBSDKAccessToken.current() != nil {
            
            // Hide all views because this screen will be shown for a split second
            for view in view.subviews {
                view.isHidden = true
            }
            
            let facebookAssetPicker = AlbumsCollectionViewController.facebookAlbumsCollectionViewController()
            facebookAssetPicker.assetPickerDelegate = facebookAssetPicker
            
            // Animated: needs to be true or else it won't show the title
            navigationController?.setViewControllers([facebookAssetPicker], animated: true)
            
            return
        } 
        
        if let navigationController = navigationController {
            facebookLogoCenterYConstraint.constant = -(navigationController.navigationBar.frame.height / 2.0)
        }
    }
    
    @IBAction private func facebookSignInTapped(_ sender: UIButton) {
        FBSDKLoginManager().logIn(withReadPermissions: ["public_profile", "user_photos"], from: self, handler: { [weak welf = self] result, error in
            if let error = error {
                welf?.present(UIAlertController(errorMessage: ErrorMessage(error)), animated: true, completion: nil)
                return
            } else if let result = result, !result.isCancelled {
                let facebookAlbumsCollectionViewController = AlbumsCollectionViewController.facebookAlbumsCollectionViewController()
                facebookAlbumsCollectionViewController.assetPickerDelegate = facebookAlbumsCollectionViewController
                welf?.navigationController?.setViewControllers([facebookAlbumsCollectionViewController], animated: false)
            }
        })
    }
}
