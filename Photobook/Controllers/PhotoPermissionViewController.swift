//
//  PhotoPermissionViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class PhotoPermissionViewController: UIViewController {
    
    @IBOutlet weak var ctaContainerView: UIView!
    @IBOutlet weak var bgImageView: UIImageView!
    
    @IBOutlet weak var ctaVisibleConstraint: NSLayoutConstraint!
    @IBOutlet weak var ctaInvisibleConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.ctaVisibleConstraint.priority = .defaultLow
        self.ctaInvisibleConstraint.priority = .init(751)
        
        self.view.layoutIfNeeded()
        
        
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appWillTerminate), name: Notification.Name.UIApplicationWillTerminate, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.dismiss(animated: false, completion: {
                
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let animationDuration:Double = 0.7
        
        self.view.layoutIfNeeded()
        
        UIView.animateKeyframes(withDuration: animationDuration, delay: 0, options: .calculationModePaced, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1, animations: {
                self.ctaVisibleConstraint.priority = .init(751)
                self.ctaInvisibleConstraint.priority = .defaultLow
                
                self.view.layoutIfNeeded()
            })
        }) { (completed) in
            
        }

    }
    
    @IBAction func askForPhotoPermission(sender: UIButton) {
        let status = PHPhotoLibrary.authorizationStatus()
    
        switch status {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ status in
                if status == .authorized {
                    self.dismiss()
                } else {
                    self.showPermissionDeniedDialog()
                }
            })
        case .denied: fallthrough
        case .restricted:
            self.showPermissionDeniedDialog()
        case .authorized: fallthrough
        default:
            self.dismiss()
        }
    }
    
    func dismiss() {
        self.dismiss(animated: true) {
            
        }
    }
    
    @objc func appWillTerminate() {
        self.ctaVisibleConstraint.priority = .defaultLow
        self.ctaInvisibleConstraint.priority = .init(751)
        
        self.view.layoutIfNeeded()
    }
    
    func showPermissionDeniedDialog() {
        
        let alertText = NSLocalizedString("Controllers/PhotoPermissionController/PermissionDeniedDialogText",
                                                       value: "Photo access is restricted, but it's needed to create beautiful photo books.\nYou can turn it on in the system settings",
                                                       comment: "Alert dialog when photo library access has been disabled")
        let alertTitle = NSLocalizedString("Controllers/PhotoPermissionController/PermissionDeniedDialogTitle",
                                                       value: "Hm...",
                                                       comment: "Alert dialog when photo library access has been disabled")
        let alertOpenSettings = NSLocalizedString("Controllers/PhotoPermissionController/PermissionDeniedDialogOpenSettings",
                                                 value: "Open Settings",
                                                 comment: "Alert dialog button when photo library access has been disabled")
        let alertOK = NSLocalizedString("Controllers/PhotoPermissionController/PermissionDeniedDialogOK",
                                                  value: "Open Settings",
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
        self.present(alert, animated: true, completion: nil)
    }

}
