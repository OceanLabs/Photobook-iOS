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
import Photos

class IntroViewController: UIViewController {
    
    static var userHasDismissed:Bool {
        get {
            return UserDefaults.standard.bool(forKey: "ly.kite.sdk.introViewController.userHasDismissed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "ly.kite.sdk.introViewController.userHasDismissed")
            UserDefaults.standard.synchronize()
        }
    }
    
    @IBOutlet weak var ctaButton: UIButton!
    @IBOutlet weak var ctaContainerView: UIView!
    @IBOutlet weak var bgImageView: UIImageView!
    
    @IBOutlet weak var ctaVisibleConstraint: NSLayoutConstraint!
    @IBOutlet weak var ctaInvisibleConstraint: NSLayoutConstraint!
    @IBOutlet weak var ctaContainerToBackgroundImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var bgImageHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ctaVisibleConstraint.priority = .defaultLow
        ctaInvisibleConstraint.priority = .init(751)
        
        if !Configuration.shouldIntroBackgroundImageScroll {
            bgImageHeightConstraint.priority = .init(751)
            ctaContainerToBackgroundImageConstraint.priority = .defaultLow
        }
        
        view.layoutIfNeeded()
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            IntroViewController.userHasDismissed = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        showIntro()
    }
    
    private func showIntro() {
        let animationDuration:Double = 0.7
        
        view.layoutIfNeeded()
        
        UIView.animateKeyframes(withDuration: animationDuration, delay: 1, options: .calculationModePaced, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                self.ctaVisibleConstraint.priority = .init(751)
                self.ctaInvisibleConstraint.priority = .defaultLow
                
                self.view.layoutIfNeeded()
            })
        })
    }
    
    @IBAction func askForPhotoPermission(sender: UIButton) {
        let status = PHPhotoLibrary.authorizationStatus()
    
        switch status {
        case .notDetermined:
            ctaButton.isEnabled = false
            PHPhotoLibrary.requestAuthorization({ [weak welf = self] status in
                DispatchQueue.main.async {
                    welf?.ctaButton.isEnabled = true
                    
                    // We don't care about the outcome, the next screens will take care of showing the user an error screen if needed
                    IntroViewController.userHasDismissed = true
                    welf?.performSegue(withIdentifier: "IntroDismiss", sender: nil)
                }
            })
        default:
            IntroViewController.userHasDismissed = true
            performSegue(withIdentifier: "IntroDismiss", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "IntroDismiss" else { return }
        
        if let tabBarController = segue.destination as? UITabBarController {
            PhotobookManager.shared.configureTabBarController(tabBarController)
        }
    }
}
