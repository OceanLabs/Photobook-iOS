//
//  PhotoBookPageView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotoBookPageView: UIView {
    
    private struct Constants{
        static let landscapeAspectRatio: CGFloat = 16.0/9.0
        static let portraitAspectRatio: CGFloat = 9.0/16.0
        static let centerRectangleRelativeSize: CGFloat = 0.8
        static let centerSquareRelativeSize: CGFloat = 0.5
    }
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak private var imageView: UIImageView! {
        didSet{
            imageView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    var index: Int?
    weak var delegate: PhotoBookViewDelegate?
    var productLayout: ProductLayout?{
        didSet{
            setupLayout()
        }
    }
    
    func setupLayout() {
        
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
    
    private func setup(){
        Bundle.main.loadNibNamed("PhotoBookPageView", owner: self, options: nil)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(contentView)
    }
    
    @IBAction func didTapOnPage(_ sender: UITapGestureRecognizer) {
        guard let index = index else { return }
        delegate?.didTapOnPage(index: index)
    }
    
}
