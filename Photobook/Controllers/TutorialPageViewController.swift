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

    static let style = "font-family: '-apple-system','HelveticaNeue'; font-size: 24; color: #000"
    
    var image: UIImage? {
        didSet {
            loadViewIfNeeded()
            imageView.image = image
        }
    }
    var text: String? {
        didSet {
            guard let text = text else { return }
            loadViewIfNeeded()
            textLabel.attributedText = NSAttributedString(html: text, style: TutorialPageViewController.style)
        }
    }
    
    override func viewDidLayoutSubviews() {
        guard let image = imageView.image else { return }
        imageView.contentMode = image.size.width < imageView.frame.width ? .center : .scaleAspectFit
    }
}
