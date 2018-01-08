//
//  PhotobookPageView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol PhotobookPageViewDelegate: class {
    func didTapOnPage(index: Int)
}

class PhotobookPageView: UIView {
    
    private var imageView: UIImageView = UIImageView()
    weak var delegate: PhotobookPageViewDelegate?
    var tapGesture: UITapGestureRecognizer!
    var productLayout: ProductLayout?
    
    var index: Int? {
        return ProductManager.shared.productLayouts.index(where: { return $0 === self.productLayout })
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let imageBox = productLayout?.layout.imageLayoutBox else { return }
        imageView.frame = imageBox.rectContained(in: CGSize(width: frame.width, height: frame.height))
    }
    
    private func setup() {
        backgroundColor = .white
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        imageView.backgroundColor = UIColor(red:0.92, green:0.92, blue:0.92, alpha:1)
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOnPage(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    @objc private func didTapOnPage(_ sender: UITapGestureRecognizer) {
        guard let index = index else { return }
        delegate?.didTapOnPage(index: index)
    }
    
}

