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
        static let textBoxFont = UIFont.systemFont(ofSize: 6.0)
    }
    
    // Constraints
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
    
    // Public settings
    var pageSizeRatio: CGFloat! {
        didSet {
            let pageWidth = view.bounds.width - Constants.pageSideMargin
            let pageHeight = pageWidth / pageSizeRatio
            pageSize = CGSize(width: pageWidth, height: pageHeight)
        }
    }
    var selectedAsset: Asset? {
        didSet {
            self.setupProductLayout()
        }
    }
    var pageText: String? = "Fields of Athenry, County Galway, Ireland" // TEMP: Test code
    var productLayout: ProductLayout!
    var availableLayouts: [Layout]!

    private var pageSize: CGSize = .zero
    
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
            
            if let photobook = ProductManager.shared.products?.first {
                ProductManager.shared.setPhotobook(photobook, withAssets: self.assets)
                self.availableLayouts = ProductManager.shared.layouts(for: photobook)
            }
            
            // Assign a default asset
            self.selectedAsset = self.assets.first!
            
            self.setupPage()
            self.setupLayoutSelection()
            
            UIView.animate(withDuration: 0.3) {
                self.pageView.alpha = 1.0
            }
        }
    }
    
    private func setupProductLayout() {
        guard productLayout == nil else { return }
        
        let layout = availableLayouts.first(where: { $0.imageLayoutBox != nil } )!
        
        let productLayoutAsset = ProductLayoutAsset()
        productLayoutAsset.asset = self.selectedAsset
        
        self.productLayout = ProductLayout(layout: layout, productLayoutAsset: productLayoutAsset, productLayoutText: nil)
    }
    
    func setupPage() {
        // TEMP: Trigger didSet code
        pageSizeRatio = 1.23
        pageHeightConstraint.constant = pageSize.height

        setupLayoutBoxes()
    }
    
    func adjustLabelHeight() {
        let textAttributes = [NSAttributedStringKey.font: Constants.textBoxFont]
        let rect = pageTextLabel.text!.boundingRect(with: CGSize(width: pageTextLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
        if rect.size.height < pageTextLabel.bounds.height {
            pageTextLabel.frame.size.height = rect.size.height
        }
    }
    
    func setupLayoutSelection() {
        layoutSelectionViewController.pageSizeRatio = pageSizeRatio
        layoutSelectionViewController.asset = selectedAsset
        layoutSelectionViewController.layouts = availableLayouts
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "LayoutSelectionSegue" {
            layoutSelectionViewController = segue.destination as! LayoutSelectionViewController
            layoutSelectionViewController.delegate = self
        }
    }
    
    private func setupLayoutBoxes() {
        if let imageBox = productLayout.layout.imageLayoutBox, let assetSize = productLayout.asset?.size {

            // Set up the image the first time this method is called
            if productLayout.asset != nil && photoImageView.image == nil {
                // FIXME: container doesn't have the right size at this point
                let maxDimension = (imageBox.isLandscape() ? photoContainerView.bounds.width : photoContainerView.bounds.height) * UIScreen.main.scale
                let imageSize = CGSize(width: maxDimension, height: maxDimension)
                // FIXME: Defaults to oportunistic whereas we would want a single request with the exact size returned here
                productLayout.asset!.image(size: imageSize, completionHandler: { (image, error) in
                    guard error == nil else {
                        print("PageSetup: error retrieving image")
                        return
                    }
                    self.photoImageView.image = image
                })
                photoImageView.frame = CGRect(x: 0.0, y: 0.0, width: assetSize.width, height: assetSize.height)
            }

            // Lay out the image box
            photoContainerView.frame = imageBox.rectContained(in: pageSize)
            photoImageView.center = CGPoint(x: photoContainerView.bounds.midX, y: photoContainerView.bounds.midY)
            
            // Apply the image box size so the transform can be re-calculated
            productLayout.productLayoutAsset!.containerSize = photoContainerView.bounds.size
            photoImageView.transform = productLayout.productLayoutAsset!.transform
            
            photoContainerView.alpha = 1.0
        } else {
            photoContainerView.alpha = 0.0
        }
        
        if let textBox = productLayout.layout.textLayoutBox, let text = pageText {
            if (pageTextLabel.text ?? "").isEmpty {
                pageTextLabel.font = Constants.textBoxFont
                pageTextLabel.text = text
            }
            pageTextLabel.frame = textBox.rectContained(in: pageSize)
            adjustLabelHeight()
            
            pageTextLabel.alpha = 1.0
        } else {
            pageTextLabel.alpha = 0.0
        }
    }
}

extension PageSetupViewController: LayoutSelectionViewControllerDelegate {
    
    func didSelectLayout(_ layout: Layout) {
        productLayout.layout = layout
        setupLayoutBoxes()
    }
    
}
