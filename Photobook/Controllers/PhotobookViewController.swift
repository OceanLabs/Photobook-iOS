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

    lazy var photobookWidth: CGFloat = {
        return (self.view.bounds.width - Constants.margin - Constants.pagePreviewMargin) * 2.0
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        PhotobookManager.shared.requestPhotobooks { [weak welf = self] (error) in
            guard error == nil else {
                print("PB: Can't retrieve photobooks")
                return
            }
            
            welf?.buildPages()
        }
    }

    func buildPages() {
        
        guard let photobook = PhotobookManager.shared.photobooks?.first else {
            print("PB: Can't find the photobook")
            return
        }
        
        PhotobookManager.shared.requestLayouts(for: photobook) { [weak welf = self] (error) in
            guard photobook.layouts != nil, welf != nil else {
                print("PB: Could not parse layouts for photobook")
                return
            }
            
            var xPosition = Constants.margin
            
            for layout in photobook.layouts {
                welf!.addLayout(layout, at: xPosition, photobook: photobook)
                xPosition += Constants.margin + welf!.photobookWidth
                welf!.scrollView.contentSize = CGSize(width: xPosition, height: welf!.scrollView.bounds.height)
            }
        }
        
    }
    
    private func addLayout(_ layout: Layout, at x: CGFloat, photobook: Photobook) {
        let pageContainerView = UIView(frame: CGRect(x: x, y: 0.0, width: photobookWidth, height: photobookWidth / photobook.pageSizeRatio))
        pageContainerView.center = CGPoint(x: pageContainerView.center.x, y: scrollView.center.y)
        pageContainerView.backgroundColor = .white
        
        scrollView.addSubview(pageContainerView)
        
        for layoutBox in layout.layoutBoxes {
            addLayoutBox(layoutBox, to: pageContainerView)
        }
    }
    
    private func addLayoutBox(_ layoutBox: LayoutBox, to containerView: UIView) {
        let origin = CGPoint(x: containerView.bounds.width * layoutBox.normalisedOrigin.x, y: containerView.bounds.height * layoutBox.normalisedOrigin.y)
        let size = CGSize(width: containerView.bounds.width * layoutBox.normalisedSize.width, height: containerView.bounds.height * layoutBox.normalisedSize.height)
        let boxView = UIView(frame: CGRect(x: origin.x, y: origin.y, width: size.width, height: size.height))
        boxView.backgroundColor = layoutBox.type == .photo ? .darkGray : .lightGray
        containerView.addSubview(boxView)
    }    
}
