//
//  PhotoBookView.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 21/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol PhotoBookViewDelegate: class{
    func didTapOnPage(index: Int)
}

class PhotoBookView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var page: PhotoBookPageView! {
        didSet{
            page.delegate = delegate
        }
    }
    weak var delegate: PhotoBookViewDelegate?
    var nibName: String { return "PhotoBookView" }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup(){
        Bundle.main.loadNibNamed(nibName, owner: self, options: nil)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        addSubview(contentView)
    }
    
}

class PhotoBookDoublePageView: PhotoBookView{
    @IBOutlet weak var rightPage: PhotoBookPageView! {
        didSet{
            page.delegate = delegate
        }
    }
    override var nibName: String { return "PhotoBookDoublePageView" }
}

class PhotoBookCoverView: PhotoBookView {
    override var nibName: String { return "PhotoBookCoverView" }
}
