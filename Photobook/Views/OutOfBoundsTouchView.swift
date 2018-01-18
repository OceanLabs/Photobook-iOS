//
//  OutOfBoundsTouchView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 12/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit


/// This view allows subviews that are outside of its frame to receive touch events
class OutOfBoundsTouchView: UIView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        for view in subviews{
            if !view.isHidden, !view.clipsToBounds, let hitView = view.hitTest(view.convert(point, from: self), with: event){
                return hitView
            }
        }
        
        return super.hitTest(point, with: event)
    }
    

}
