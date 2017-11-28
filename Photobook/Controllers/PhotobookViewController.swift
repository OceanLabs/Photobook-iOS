//
//  PhotobookViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 17/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class PhotobookViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    
    private struct Constants {
        static let margin: CGFloat = 20.0
        static let pagePreviewMargin: CGFloat = 40.0
    }

    lazy var pageWidth: CGFloat = {
        return self.view.bounds.width - Constants.margin - Constants.pagePreviewMargin
    }()
    
    var layouts: [Layout]!
    var photobooks: [Photobook]!

    override func viewDidLoad() {
        super.viewDidLoad()

        PhotobookAPIManager.shared.requestPhotobookInfo { [weak welf = self] (photobooks, layouts, error) in
            guard error == nil, (photobooks ?? []).count > 0, (layouts ?? []).count > 0 else {
                print("PB: Can't retrieve photobooks")
                return
            }
            
            welf?.photobooks = photobooks
            welf?.layouts = layouts
            
            welf?.buildPages()
        }
    }

    func buildPages() {
        
        var xPosition = Constants.margin
        
        var i = 0
        for layout in layouts {
            addLayout(layout, at: xPosition, photobook: photobooks.first!)
            xPosition += (i % 2 == 1 ? Constants.margin + pageWidth : pageWidth)
            scrollView.contentSize = CGSize(width: xPosition, height: scrollView.bounds.height)
            i += 1
        }
    }
    
    private func addLayout(_ layout: Layout, at x: CGFloat, photobook: Photobook) {
        let pageContainerView = UIView(frame: CGRect(x: x, y: 0.0, width: pageWidth, height: pageWidth / photobook.pageSizeRatio))
        pageContainerView.center = CGPoint(x: pageContainerView.center.x, y: scrollView.center.y)
        pageContainerView.backgroundColor = .white
        
        scrollView.addSubview(pageContainerView)
        
        if let imageLayoutBox = layout.imageLayoutBox {
            addLayoutBox(imageLayoutBox, color: .darkGray, to: pageContainerView)
        }
        
        if let textLayoutBox = layout.textLayoutBox {
            addLayoutBox(textLayoutBox, color: .lightGray, to: pageContainerView)
        }
    }
    
    private func addLayoutBox(_ layoutBox: LayoutBox, color: UIColor, to containerView: UIView) {
        let origin = CGPoint(x: containerView.bounds.width * layoutBox.rect.minX, y: containerView.bounds.height * layoutBox.rect.minY)
        let size = CGSize(width: containerView.bounds.width * layoutBox.rect.width, height: containerView.bounds.height * layoutBox.rect.height)
        let boxView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height))
        boxView.backgroundColor = color
        containerView.addSubview(boxView)
    }
}
