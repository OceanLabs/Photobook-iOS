//
//  AssetPlacementViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 28/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class AssetPlacementViewController: UIViewController {
    
    private struct Constants {
        static let sideMargins: CGFloat = 40.0
    }
    
    @IBOutlet private weak var imageBoxView: UIView!
    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet private weak var imageBoxViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var imageBoxViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var assetEditingAreaView: UIView!
    
    private var hasDoneInitialSetup = false
    
    // Public vars
    var productLayout: ProductLayout? {
        didSet {
            hasDoneInitialSetup = false
            setupUI()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imageBoxView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupUI()
    }
    
    func setupUI() {
        guard !hasDoneInitialSetup,
              assetImageView != nil,
              let productLayout = productLayout,
              let containerSize = productLayout.productLayoutAsset?.containerSize else { return }
        
        hasDoneInitialSetup = true
        
        setUpLayoutImageBox(withRatio: containerSize.height / containerSize.width)
        setUpImageView(withProductLayout: productLayout)
    }
    
    private func setUpLayoutImageBox(withRatio ratio: CGFloat) {
        // Calculate new container size
        var width: CGFloat!
        var height: CGFloat!
        let maxWidth = assetEditingAreaView.bounds.width - Constants.sideMargins * 2.0

        if ratio < 1.0 { // Landscape
            width = maxWidth
            height = width * ratio
        } else { // Portrait
            height = assetEditingAreaView.bounds.height - Constants.sideMargins * 2.0
            width = height / ratio
            if width >= maxWidth {
                width = maxWidth
                height = maxWidth * ratio
            }
        }
        
        imageBoxViewWidthConstraint.constant = floor(width)
        imageBoxViewHeightConstraint.constant = floor(height)
    }
    
    private func setUpImageView(withProductLayout productLayout: ProductLayout) {
        guard let asset = productLayout.asset else {
            assetImageView.alpha = 0.0
            return
        }
        
        assetImageView.alpha = 1.0
        
        // Reset to default imageView frame
        assetImageView.transform = .identity
        assetImageView.frame = CGRect(x: 0.0, y: 0.0, width: asset.size.width, height: asset.size.height)

        // Should trigger a transform recalculation
        productLayout.productLayoutAsset?.containerSize = CGSize(width: imageBoxViewWidthConstraint.constant, height: imageBoxViewHeightConstraint.constant)
        assetImageView.transform = productLayout.productLayoutAsset!.transform
        
        assetImageView.center = CGPoint(x: imageBoxViewWidthConstraint.constant * 0.5, y: imageBoxViewHeightConstraint.constant * 0.5)
        
        productLayout.asset?.image(size: asset.size, completionHandler: { [weak welf = self] (image, error) in
            guard error == nil else {
                // TODO: Display error
                return
            }
            
            welf?.assetImageView.image = image
        })
    }
    
    @IBAction private func tappedRotateButton(_ sender: UIButton) {
        
    }
}
