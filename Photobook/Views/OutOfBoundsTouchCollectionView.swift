//
//  OutOfBoundsTouchCollectionView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 12/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

/// This collectionView allows views that are outside of its cells' frame to receive touch events
class OutOfBoundsTouchCollectionView: UICollectionView {
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for cell in visibleCells{
            for view in cell.contentView.subviews.reversed(){
                if !view.isHidden, let hitView = view.hitTest(view.convert(point, from: self), with: event){
                    return hitView
                }
            }
        }
        
        return super.hitTest(point, with: event)
    }
    
}
