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
    
    weak var delegate: PhotobookPageViewDelegate?
    var index: Int?
    
    private var tapGesture: UITapGestureRecognizer!
    private var productLayout: ProductLayout? {
        guard let index = index else { return nil }
        return ProductManager.shared.productLayouts[index]
    }
    
    @IBOutlet private weak var assetContainerView: UIView!
    @IBOutlet private weak var assetPlaceholderIconImageView: UIImageView!
    @IBOutlet private weak var assetImageView: UIImageView!
    
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
        assetContainerView.frame = imageBox.rectContained(in: CGSize(width: frame.width, height: frame.height))
        assetPlaceholderIconImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
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
    
    func load(size: CGSize) {
        setImage(image: nil)
        
        guard let index = index else {
            isHidden = true
            return
        }
        isHidden = false
        
        guard let imageBox = productLayout?.layout.imageLayoutBox else {
            assetContainerView.alpha = 0.0
            return
        }
        assetContainerView.alpha = 1.0
        assetContainerView.frame = imageBox.rectContained(in: CGSize(width: frame.width, height: frame.height))
        
        guard let asset = productLayout?.productLayoutAsset?.asset else {
            setImagePlaceholder(visible: true)
            return
        }
        
        asset.image(size: size, completionHandler: { [weak welf = self] (image, _) in
            guard welf?.index == index, let image = image else { return }
            welf?.setImage(image: image)
        })
    }
    
    func setImage(image: UIImage?) {
        guard let image = image, let asset = productLayout?.productLayoutAsset?.asset else {
            setImagePlaceholder(visible: true)
            return
        }
        
        setImagePlaceholder(visible: false)
        
        assetImageView.image = image
        assetImageView.transform = .identity
        assetImageView.frame = CGRect(x: 0.0, y: 0.0, width: asset.size.width, height: asset.size.height)
        assetImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
        
        productLayout!.productLayoutAsset!.containerSize = assetContainerView.bounds.size
        assetImageView.transform = productLayout!.productLayoutAsset!.transform
    }
    
    func setImagePlaceholder(visible: Bool) {
        if visible {
            assetImageView.image = nil
            assetContainerView.backgroundColor = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1.0)
            assetPlaceholderIconImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
            assetPlaceholderIconImageView.alpha = 1.0
        } else {
            assetContainerView.backgroundColor = .clear
            assetPlaceholderIconImageView.alpha = 0.0
        }
    }
    
    @objc private func didTapOnPage(_ sender: UITapGestureRecognizer) {
        guard let index = index else { return }
        delegate?.didTapOnPage(index: index)
    }
}

