//
//  PhotoBookTabBar.swift
//  Photobook
//
//  Created by Jaime Landazuri on 10/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookTabBar: UITabBar {
    
    var effectView: UIVisualEffectView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        effectView?.frame = bounds
    }
    
    func setup() {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        self.effectView = effectView
        
        effectView.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        insertSubview(effectView, at: 0)
        backgroundImage = UIImage(color: .clear)
        shadowImage = UIImage()
    }
}
