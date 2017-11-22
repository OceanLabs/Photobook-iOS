//
//  PhotoBookView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var leftPage: PhotoBookPageView!
    @IBOutlet weak var rightPage: PhotoBookPageView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup(){
        Bundle.main.loadNibNamed("PhotoBookView", owner: self, options: nil)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(contentView)
    }
    
    
}
