//
//  SelectedAssetsManager.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 08/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit


/// Temporary class to hold selected assets. Replace with whatever solution is implemented in PHO-5
class SelectedAssetsManager: NSObject {

    private static var selectedAssets = [String:[Asset]]()
    
    static func selectedAssets(_ album: Album) -> Int{
        let assets = selectedAssets[album.identifier]
        if assets == nil{
            selectedAssets[album.identifier] = [Asset]()
        }
        
        return selectedAssets[album.identifier]!.count
    }
    
}
