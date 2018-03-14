//
//  CGSizeExtensions.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 13/03/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import Foundation

extension CGSize{
    
    func resizeAspectFill(_ targetSize: CGSize) -> CGSize {
        let sourceAspectRatio = self.width / self.height
        let targetAspectRatio = targetSize.width / targetSize.height
        
        if sourceAspectRatio >= targetAspectRatio{
            return CGSize(width: targetSize.height * sourceAspectRatio, height: targetSize.height)
        }
        else{
            return CGSize(width: targetSize.width, height: targetSize.width / sourceAspectRatio)
        }
    }
}
