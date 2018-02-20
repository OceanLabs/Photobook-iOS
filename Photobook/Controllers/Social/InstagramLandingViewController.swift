//
//  InstagramLandingViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 20/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class InstagramLandingViewController: UIViewController {

    @IBOutlet weak var instagramLogoCenterYConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let navigationController = navigationController {
            instagramLogoCenterYConstraint.constant = -(navigationController.navigationBar.frame.height / 2.0)
        }
    }

}
