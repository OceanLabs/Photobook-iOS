//
//  SelectedAssetsManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class SelectedAssetsManager: NSObject {

    private static var selectedAssets = [String:[Asset]]()
    
    static func selectedAssets(_ album: Album) -> [Asset]{
        let assets = selectedAssets[album.identifier]
        if assets == nil{
            selectedAssets[album.identifier] = [Asset]()
        }
        
        return selectedAssets[album.identifier]!
    }
    
}
