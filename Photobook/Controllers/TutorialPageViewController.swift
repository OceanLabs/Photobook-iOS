//
//  TutorialPageViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 23/10/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIViewController {

    @IBOutlet private var imageView: UIImageView!
    @IBOutlet private var textLabel: UILabel!
    
    var image: UIImage? {
        didSet {
            loadViewIfNeeded()
            imageView.image = image
        }
    }
    var text: String? {
        didSet {
            loadViewIfNeeded()
            textLabel.text = text
        }
    }
}
