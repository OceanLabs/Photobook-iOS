//
//  ActionButtonView.swift
//  Photobook
//
//  Created by Jaime Landazuri on 10/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ActionButtonView: UIView {

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var label: UILabel!
    
    var title: String? { didSet { label.text = title } }
    var image: UIImage? { didSet { imageView.image = image } }    
    var action: ((ActionButtonView) -> ())!
    
    @IBAction func tappedOnActionButton(_ sender: UIButton) {
        action(self)
    }
}
