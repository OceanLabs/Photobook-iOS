//
//  PageSetupViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 13/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol PageSetupDelegate: class {
    func didFinishEditingPage(_ index: Int, productLayout: ProductLayout, saving: Bool)
}

class PageSetupViewController: UIViewController {

    private struct Constants {
        static let pageSideMargin: CGFloat = 20.0
        static let textBoxFont = UIFont.systemFont(ofSize: 6.0)
    }
    
    private enum Tools: Int {
        case selectAsset, selectLayout, placeAsset, editColor
    }
    
    // Constraints
    @IBOutlet private weak var pageWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var pageHeightConstraint: NSLayoutConstraint!
    
    // Outlets
    @IBOutlet private weak var pageView: UIView! {
        didSet {
            pageView.translatesAutoresizingMaskIntoConstraints = false
        }
    }
    @IBOutlet private weak var assetSelectionContainerView: UIView!
    @IBOutlet private weak var layoutSelectionContainerView: UIView!
    @IBOutlet private weak var placementContainerView: UIView!
    @IBOutlet private weak var assetContainerView: UIView!
    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet private weak var assetPlaceholderIconImageView: UIImageView!
    @IBOutlet private weak var pageTextLabel: UILabel!
    
    @IBOutlet var toolbarButtons: [UIButton]!
    @IBOutlet weak var toolbar: UIToolbar!
    
    private var assetSelectorViewController: AssetSelectorViewController!
    private var layoutSelectionViewController: LayoutSelectionViewController!
    private var assetPlacementViewController: AssetPlacementViewController!
    
    // Public settings
    weak var delegate: PageSetupDelegate?
    var selectedAssetsManager: SelectedAssetsManager!
    var pageIndex: Int!
    var pageSizeRatio: CGFloat! {
        didSet {
            let pageWidth = view.bounds.width - Constants.pageSideMargin
            let pageHeight = pageWidth / pageSizeRatio
            pageSize = CGSize(width: pageWidth, height: pageHeight)
            pageWidthConstraint.constant = pageWidth
            pageHeightConstraint.constant = pageSize.height
        }
    }
    var pageText: String? = "Fields of Athenry, County Galway, Ireland" // TEMP: Test code
    var productLayout: ProductLayout!
    var availableLayouts: [Layout]!

    private var pageSize: CGSize = .zero
    private var hasDoneSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageView.alpha = 0.0
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbarButtons[Tools.selectAsset.rawValue].isSelected = true
        
        UIView.animate(withDuration: 0.3) {
            self.pageView.alpha = 1.0
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasDoneSetup {
            setupLayoutBoxes()
            setupAssetSelection()
            setupLayoutSelection()
            hasDoneSetup = true
        }
    }
    
    private func adjustLabelHeight() {
        let textAttributes = [NSAttributedStringKey.font: Constants.textBoxFont]
        let rect = pageTextLabel.text!.boundingRect(with: CGSize(width: pageTextLabel.bounds.width, height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: textAttributes, context: nil)
        if rect.size.height < pageTextLabel.bounds.height {
            pageTextLabel.frame.size.height = rect.size.height
        }
    }
    
    private func setupAssetSelection() {
        assetSelectorViewController.selectedAssetsManager = selectedAssetsManager
        assetSelectorViewController.selectedAsset = productLayout.asset
    }
    
    private func setupLayoutSelection() {
        layoutSelectionViewController.pageSizeRatio = pageSizeRatio
        layoutSelectionViewController.asset = productLayout.asset
        layoutSelectionViewController.layouts = availableLayouts
        layoutSelectionViewController.selectedLayout = productLayout!.layout
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        switch identifier {
        case "AssetSelectionSegue":
            assetSelectorViewController = segue.destination as! AssetSelectorViewController
            assetSelectorViewController.delegate = self
        case "LayoutSelectionSegue":
            layoutSelectionViewController = segue.destination as! LayoutSelectionViewController
            layoutSelectionViewController.delegate = self
        case "PlacementSegue":
            assetPlacementViewController = segue.destination as! AssetPlacementViewController
        default:
            break
        }
    }
    
    private func setupLayoutBoxes() {
        setupImageBox()
        setupTextBox()
    }
    
    private func setupImageBox() {
        UIView.animate(withDuration: 0.1) {
            self.assetContainerView.alpha = 0.0
        }
        
        if let imageBox = productLayout.layout.imageLayoutBox, let assetSize = productLayout.asset?.size {
            // Lay out the image box
            assetContainerView.frame = imageBox.rectContained(in: pageSize)
            
            // Set up the image if there is an asset
            if productLayout.asset != nil {
                let maxDimension = (imageBox.isLandscape() ? assetContainerView.bounds.width : assetContainerView.bounds.height) * UIScreen.main.scale
                let imageSize = CGSize(width: maxDimension, height: maxDimension)
                
                productLayout.asset!.image(size: imageSize, completionHandler: { (image, error) in
                    guard error == nil else {
                        print("PageSetup: error retrieving image")
                        return
                    }
                    self.assetImageView.image = image
                })
                assetImageView.transform = .identity
                assetImageView.frame = CGRect(x: 0.0, y: 0.0, width: assetSize.width, height: assetSize.height)
            }
            
            assetImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
            
            // Apply the image box size so the transform can be re-calculated
            productLayout.productLayoutAsset!.containerSize = assetContainerView.bounds.size
            assetImageView.transform = productLayout.productLayoutAsset!.transform
            
            toolbarButtons[Tools.placeAsset.rawValue].isEnabled = true
            
            UIView.animate(withDuration: 0.2, delay: 0.1, options: [], animations: {
                self.assetContainerView.alpha = 1.0
            })
        } else {
            // Disable the asset placement screen
            toolbarButtons[Tools.placeAsset.rawValue].isEnabled = false
            setImagePlaceholder(visible: true)
        }
    }
    
    private func setupTextBox() {
        UIView.animate(withDuration: 0.1) {
            self.pageTextLabel.alpha = 0.0
        }

        if let textBox = productLayout.layout.textLayoutBox, let text = pageText {
            if (pageTextLabel.text ?? "").isEmpty {
                pageTextLabel.font = Constants.textBoxFont
                pageTextLabel.text = text
            }
            pageTextLabel.frame = textBox.rectContained(in: pageSize)
            adjustLabelHeight()
            
            UIView.animate(withDuration: 0.2, delay: 0.1, options: [], animations: {
                self.pageTextLabel.alpha = 1.0
            })

        }
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
    
    @IBAction func tappedCancelButton(_ sender: UIBarButtonItem) {
        delegate?.didFinishEditingPage(pageIndex, productLayout: productLayout, saving: false)
    }
    
    @IBAction func tappedDoneButton(_ sender: UIBarButtonItem) {
        if productLayout.layout.imageLayoutBox == nil {
            // Remove the asset if the layout doesn't have an image box
            productLayout.asset = nil
        }
        delegate?.didFinishEditingPage(pageIndex, productLayout: productLayout, saving: true)
    }
    
    @IBAction func tappedToolButton(_ sender: UIButton) {
        
        guard let index = toolbarButtons.index(of: sender),
            !toolbarButtons[index].isSelected,
            let tool = Tools(rawValue: index) else { return }

        let editLayoutWasSelected = toolbarButtons[Tools.placeAsset.rawValue].isSelected
        
        for button in toolbarButtons {
            button.isSelected = (button === sender)
        }
        
        switch tool {
        case .selectAsset, .selectLayout:
            if editLayoutWasSelected {
                assetPlacementViewController.animateBackToPhotobook {
                    self.assetImageView.transform = self.productLayout!.productLayoutAsset!.transform
                    self.view.sendSubview(toBack: self.placementContainerView)
                }
            }
            UIView.animate(withDuration: 0.1, animations: {
                self.assetSelectionContainerView.alpha = tool.rawValue == Tools.selectAsset.rawValue ? 1.0 : 0.0
                self.layoutSelectionContainerView.alpha = tool.rawValue == Tools.selectLayout.rawValue ? 1.0 : 0.0
            })
            break
        case .placeAsset:
            view.bringSubview(toFront: placementContainerView)
            
            let containerRect = placementContainerView.convert(assetContainerView.frame, from: pageView)
            assetPlacementViewController.productLayout = productLayout
            assetPlacementViewController.initialContainerRect = containerRect
            assetPlacementViewController.assetImage = assetImageView.image
            assetPlacementViewController.animateFromPhotobook()
            break
        case .editColor:
            break
        }
    }
}

extension PageSetupViewController: LayoutSelectionViewControllerDelegate {
    
    func didSelectLayout(_ layout: Layout) {
        productLayout.layout = layout
        
        // Deselect the asset if the layout does not have an image box
        if productLayout.layout.imageLayoutBox == nil {
            assetSelectorViewController.selectedAsset = nil
        }
        setupLayoutBoxes()
    }
}

extension PageSetupViewController: AssetSelectorDelegate {
    
    func didSelect(asset: Asset) {
        productLayout.asset = asset
        layoutSelectionViewController.asset = asset
        
        // If the current layout does not have an image box, find the first layout that does and use it
        if productLayout.layout.imageLayoutBox == nil {
            let defaultLayout = availableLayouts.first(where: { $0.imageLayoutBox != nil })
            productLayout.layout = defaultLayout
            setupTextBox()
            layoutSelectionViewController.selectedLayout = productLayout.layout
        }
        setupImageBox()
    }    
}
