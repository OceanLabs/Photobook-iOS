//
//  TabBarController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 13/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let albumViewController = (viewControllers?[1] as? UINavigationController)?.topViewController as? AlbumsCollectionViewController{
            albumViewController.albumManager = PhotosAlbumManager()
        }
        
    }

}
