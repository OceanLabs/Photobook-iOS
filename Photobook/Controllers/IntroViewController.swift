//
//  IntroViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ctaVisibleConstraint.priority = .defaultLow
        ctaInvisibleConstraint.priority = .init(751)
        
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
            PhotobookManager.configureTabBarController(tabBarController)
        }
    }
}
