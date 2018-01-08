//
//  PhotoBookNavigationBar.swift
//  Photobook
//
//  Created by Jaime Landazuri on 09/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookNavigationBar: UINavigationBar {
    
    private static let navigationBarHeight: CGFloat = 44.0
    
    var hasAddedBlur = false
    var effectView: UIVisualEffectView!
    
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
        if !hasAddedBlur {
            hasAddedBlur = true
            
            let statusBarHeight = UIApplication.shared.statusBarFrame.height
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
            effectView.frame = CGRect(x: 0.0, y: -statusBarHeight, width: bounds.width, height: PhotobookNavigationBar.navigationBarHeight + statusBarHeight)
            effectView.backgroundColor = UIColor(white: 1.0, alpha: 0.75)
            insertSubview(effectView, at: 0)
        }
        sendSubview(toBack: effectView)
    }
    
    func setup() {
        barTintColor = .white
        prefersLargeTitles = true
        
        setBackgroundImage(UIImage(color: .clear), for: .default)
        shadowImage = UIImage()
    }
    
}

extension PhotobookNavigationBar: UINavigationControllerDelegate{
    
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool){
        if viewController as? PhotoBookViewController != nil{
            barTintColor = UIColor(red:0.89, green:0.9, blue:0.9, alpha:1)
            effectView.alpha = 0
        }
        else{
            barTintColor = .white
            effectView.alpha = 1
        }
    }
    
}
