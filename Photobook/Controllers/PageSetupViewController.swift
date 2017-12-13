//
//  PageSetupViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 13/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit
import Photos

class PageSetupViewController: UIViewController {

    private struct Constants {
        static let pageSideMargin: CGFloat = 20.0
    }
    
    // Constraints
    @IBOutlet weak var pageWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pageHorizontalAlignmentConstraint: NSLayoutConstraint!
    
    // Outlets
    @IBOutlet private weak var pageView: UIView! {
        didSet {
            pageView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    @IBOutlet private weak var photoContainerView: UIView!
    @IBOutlet private weak var photoImageView: UIImageView!
    @IBOutlet private weak var pageTextLabel: UILabel!
    
    private var layoutSelectionViewController: LayoutSelectionViewController!
    
    // TEMP
    var assets: [Asset] = {
        let options = PHFetchOptions()
        options.fetchLimit = 1
        let phAssets = PHAsset.fetchAssets(with: options)
        
        var assets = [PhotosAsset]()
        phAssets.enumerateObjects { (asset, _, _) in
            let photoAsset = PhotosAsset(asset)
            assets.append(photoAsset)
        }
        return assets
    }()
    
    var photobook: Photobook!
    var asset: Asset! {
        didSet {
            setupWithAsset()
        }
    }
    var productLayout: ProductLayout!
    
    var pageSize: CGSize!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageView.alpha = 0.0
        
        // TEMP: Remove when this is provided by the previous screen
        setupFakePhotobookData()
    }
    
    func setupFakePhotobookData() {
        ProductManager.shared.initialise { (error) in
            guard error == nil else {
                print("Error initialising the product manager")
                return
            }
            
            // Assign a default asset
            self.asset = self.assets.first!
            
            self.setupPage()
            self.setupLayoutSelection()
            
            UIView.animate(withDuration: 0.3) {
                self.pageView.alpha = 1.0
            }
        }
    }
    
    private func setupWithAsset() {
        guard productLayout == nil else { return }
        
        if let photobook = ProductManager.shared.products?.first {
            self.photobook = photobook
            
            ProductManager.shared.setPhotobook(photobook, withAssets: assets)
            
            let layout = ProductManager.shared.layouts!.first(where: { $0.imageLayoutBox != nil } )!
            
            let productLayoutAsset = ProductLayoutAsset()
            productLayoutAsset.asset = self.asset
            
            self.productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset, productLayoutText: nil)
        }
    }
    
    func setupPage() {
        // TODO: Might be the cover
        let pageWidth = view.bounds.width - Constants.pageSideMargin
        let pageHeight = pageWidth / photobook.pageSizeRatio
        pageSize = CGSize(width: pageWidth, height: pageHeight)
        
        pageHeightConstraint.constant = pageHeight
        
        if let imageBox = productLayout.layout.imageLayoutBox {
            photoContainerView.frame = imageBox.rectContained(in: CGSize(width: pageWidth, height: pageHeight))
            photoImageView.frame = CGRect(x: 0.0, y: 0.0, width: asset.size.width, height: asset.size.height)
            photoImageView.center = CGPoint(x: photoContainerView.bounds.midX, y: photoContainerView.bounds.midY)
            
            productLayout.productLayoutAsset!.containerSize = photoContainerView.bounds.size
            
            let maxDimension = (imageBox.isLandscape() ? photoContainerView.bounds.width : photoContainerView.bounds.height) * UIScreen.main.scale
            let imageSize = CGSize(width: maxDimension, height: maxDimension)
            productLayout.productLayoutAsset!.asset!.image(size: imageSize, completionHandler: { (image, error) in
                guard error == nil else {
                    print("PageSetup: error retrieving image")
                    return
                }
                self.photoImageView.image = image
            })
            photoImageView.transform = productLayout.productLayoutAsset!.transform
        } else {
            photoContainerView.alpha = 0.0
        }
        
        if let textBox = productLayout.layout.textLayoutBox {
            pageTextLabel.frame = textBox.rectContained(in: CGSize(width: pageWidth, height: pageHeight))
        } else {
            pageTextLabel.alpha = 0.0
        }
    }
    
    func setupLayoutSelection() {
        layoutSelectionViewController.layouts = ProductManager.shared.layouts(for: photobook)
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LayoutSelectionSegue" {
            layoutSelectionViewController = segue.destination as! LayoutSelectionViewController
            layoutSelectionViewController.delegate = self
        }
    }
}

extension PageSetupViewController: LayoutSelectionViewControllerDelegate {
    
    func didSelectLayout(_ layout: Layout) {
        productLayout.layout = layout
        
        if let imageBox = productLayout.layout.imageLayoutBox {
            photoContainerView.frame = imageBox.rectContained(in: pageSize)
            photoImageView.center = CGPoint(x: photoContainerView.bounds.midX, y: photoContainerView.bounds.midY)
            
            productLayout.productLayoutAsset!.containerSize = photoContainerView.bounds.size
            photoImageView.transform = productLayout.productLayoutAsset!.transform
            
            photoContainerView.alpha = 1.0
        } else {
            photoContainerView.alpha = 0.0
        }
        
        if let textBox = productLayout.layout.textLayoutBox {
            pageTextLabel.frame = textBox.rectContained(in: pageSize)
            
            pageTextLabel.alpha = 1.0
        } else {
            pageTextLabel.alpha = 0.0
        }
    }
    
}
