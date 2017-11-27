//
//  PhotoBookPageView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

enum PageLayout{
    case centerLandscape
    case centerPortrait
    case centerSquare
    case custom
}

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
    var relativeFrame: CGRect?{
        didSet{
            pageLayout = .custom
        }
    }
    
    
    var pageLayout: PageLayout? {
        didSet{
            guard let pageLayout = pageLayout else { return }
            
            // Clear previous constraints
            removeConstraints(constraints)
            imageView.removeConstraints(imageView.constraints)
            
            switch pageLayout {
            case .centerLandscape:
                imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: Constants.landscapeAspectRatio, constant: 0))
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                imageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: Constants.centerRectangleRelativeSize).isActive = true
            case .centerPortrait:
                imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: Constants.portraitAspectRatio, constant: 0))
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: Constants.centerRectangleRelativeSize).isActive = true
            case .centerSquare:
                imageView.addConstraint(NSLayoutConstraint(item: imageView, attribute: .width, relatedBy: .equal, toItem: imageView, attribute: .height, multiplier: 1, constant: 0))
                imageView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
                imageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
                imageView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: Constants.centerSquareRelativeSize).isActive = true
            case .custom:
                guard let frame = relativeFrame else { break }
                imageView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: frame.size.width).isActive = true
                imageView.heightAnchor.constraint(equalTo: self.heightAnchor, multiplier: frame.size.height).isActive = true
                addConstraint(NSLayoutConstraint(item: imageView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: frame.origin.x + frame.size.width, constant: 0))
                addConstraint(NSLayoutConstraint(item: imageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: frame.origin.y + frame.size.height, constant: 0))
            }
            
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    func setImage (image: UIImage?, contentMode: UIViewContentMode? = nil) {
        if let contentMode = contentMode{
            imageView.contentMode = contentMode
            
            if contentMode == .center{
                // Placeholder asset
                pageLayout = .centerSquare
            }
        }
        imageView.image = image
        
        guard pageLayout == nil, let image = image else { return }
        // By default the aspect ratio of the image view will use the aspect ratio of the image.
        let imageAspectRatio = image.size.width / image.size.height
        if imageAspectRatio == 1{
            pageLayout = .centerSquare
        }
        pageLayout = imageAspectRatio > 1 ? .centerLandscape : .centerPortrait
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
