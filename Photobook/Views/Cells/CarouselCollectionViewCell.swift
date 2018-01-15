//
//  CarouselCollectionViewCell.swift
//  Photobook
//
//  Created by Julian Gruber on 12/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class CarouselCollectionViewCell: UICollectionViewCell {
    
    static let reuseIdentifier = NSStringFromClass(CarouselCollectionViewCell.self).components(separatedBy: ".").last!
    
    @IBOutlet private var imageView: UIImageView!
    
    var imageUrl: URL? {
        didSet {
            if let url = imageUrl {
                UIImage.async(url) { (success, image) in
                    self.imageView.image = image
                }
            }
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.imageView.alpha = self.isHighlighted ? 0.7 : 1.0
            }
        }
    }
    
}
