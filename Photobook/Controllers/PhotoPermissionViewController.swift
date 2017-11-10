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

    @IBOutlet weak var ctaButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
    
    func showPermissionDeniedDialog() {
        let alert = UIAlertController(title: "Alert", message: "Photo access is restricted, but needed to create beautiful photo books.\nYou can turn it on in the system settings", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Open Settings", style: UIAlertActionStyle.default, handler: { (action) in
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.open(appSettings, options: [:], completionHandler: { (success) in
                    
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: { (action) in
            
        }))
        self.present(alert, animated: true, completion: nil)
    }

}
