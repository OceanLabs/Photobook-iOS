//
//  PhotoPermissionViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class IntroViewController: UIViewController {
    
    public static var userHasDismissed:Bool {
        get {
            return UserDefaults.standard.bool(forKey: "IntroViewController.userHasDismissed")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "IntroViewController.userHasDismissed")
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            dismiss()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
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
            PHPhotoLibrary.requestAuthorization({ status in
                DispatchQueue.main.async {
                    self.ctaButton.isEnabled = true
                    if status == .authorized {
                        self.dismiss()
                    } else {
                        self.showPermissionDeniedDialog()
                    }
                }
            })
        case .denied: fallthrough
        case .restricted:
            showPermissionDeniedDialog()
        case .authorized: fallthrough
        default:
            dismiss()
        }
    }
    
    func dismiss() {
        performSegue(withIdentifier: "IntroDismiss", sender: nil)
        IntroViewController.userHasDismissed = true
    }
    
    func showPermissionDeniedDialog() {
        
        let alertText = NSLocalizedString("Controllers/IntroViewController/PermissionDeniedDialogText",
                                                       value: "Photo access has been restricted, but it's needed to create beautiful photo books.\nYou can turn it back on in the system settings",
                                                       comment: "Alert dialog when photo library access has been disabled")
        let alertTitle = NSLocalizedString("Controllers/IntroViewController/PermissionDeniedDialogTitle",
                                                       value: "Photo Access",
                                                       comment: "Alert dialog when photo library access has been disabled")
        let alertOpenSettings = NSLocalizedString("Controllers/PhotoPermissionController/PermissionDeniedDialogOpenSettings",
                                                 value: "Open Settings",
                                                 comment: "Alert dialog button when photo library access has been disabled")
        let alertOK = NSLocalizedString("Controllers/IntroViewController/PermissionDeniedDialogOK",
                                                  value: "OK",
                                                  comment: "Alert dialog button when photo library access has been disabled")
        
        
        let alert = UIAlertController(title: alertTitle, message: alertText, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: alertOpenSettings, style: UIAlertActionStyle.default, handler: { (action) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: { (success) in
                    
                })
            }
        }))
        alert.addAction(UIAlertAction(title: alertOK, style: UIAlertActionStyle.cancel, handler: { (action) in
            
        }))
        present(alert, animated: true, completion: nil)
    }

}
