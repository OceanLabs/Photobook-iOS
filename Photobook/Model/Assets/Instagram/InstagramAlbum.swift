//
//  InstagramAlbum.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 15/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class InstagramAlbum: Album {
    var numberOfAssets: Int = 0
    
    var localizedName: String?
    
    var identifier: String = ""
    
    var assets: [Asset] = []
    
    var requiresExclusivePicking: Bool = true
    
    func loadAssets(completionHandler: ((Error?) -> Void)?) {
        
    }
    
    func coverAsset(completionHandler: @escaping (Asset?, Error?) -> Void) {
        
    }
    

}
