//
//  PhotoBookPageView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol PhotoBookPageViewDelegate: class {
    func didTapOnPage(index: Int)
}

class PhotoBookPageView: UIView {
    
    private var imageView: UIImageView = UIImageView()
    var index: Int?
    weak var delegate: PhotoBookPageViewDelegate?
    var productLayout: ProductLayout?{
        didSet{
            setupLayout()
        }
    }
    
    private func setupLayout() {
        
        // Clear previous constraints
        removeConstraints(constraints)
        imageView.removeConstraints(imageView.constraints)
        
        guard let imageFrame = productLayout?.layout.imageLayoutBox?.rect else { return }
        imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: imageFrame.size.width).isActive = true
        imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: imageFrame.size.height).isActive = true
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: imageFrame.origin.x + imageFrame.size.width, constant: 0))
        addConstraint(NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: imageFrame.origin.y + imageFrame.size.height, constant: 0))
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func setImage (image: UIImage?, contentMode: UIViewContentMode? = nil) {
        if let contentMode = contentMode{
            imageView.contentMode = contentMode
        }
        imageView.isHidden = image == nil
        imageView.image = image
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        imageView.backgroundColor = UIColor(red:0.92, green:0.92, blue:0.92, alpha:1)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOnPage(_:))))
    }
    
    @objc private func didTapOnPage(_ sender: UITapGestureRecognizer) {
        guard let index = index else { return }
        delegate?.didTapOnPage(index: index)
    }
    
}

