//
//  PhotobookTabBarController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 20/04/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookTabBarController: UITabBarController {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }

}
