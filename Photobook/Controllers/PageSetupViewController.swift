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

enum PageType {
    case cover, first, last, left, right
}

class PageSetupViewController: UIViewController {

    private struct Constants {
        static let pageSideMargin: CGFloat = 20.0
        static let photobookSideMargin: CGFloat = 20.0
        static let textBoxFont = UIFont.systemFont(ofSize: 6.0)
    }
    
    private enum Tools: Int {
        case selectAsset, selectLayout, placeAsset, editColor
    }
    
    @IBOutlet private weak var assetSelectionContainerView: UIView!
    @IBOutlet private weak var layoutSelectionContainerView: UIView!
    @IBOutlet private weak var placementContainerView: UIView!
    
    @IBOutlet var toolbarButtons: [UIButton]!
    @IBOutlet weak var toolbar: UIToolbar!
    
    private var assetSelectorViewController: AssetSelectorViewController!
    private var layoutSelectionViewController: LayoutSelectionViewController!
    private var assetPlacementViewController: AssetPlacementViewController!
    
    @IBOutlet private weak var coverFrameView: CoverFrameView! {
        didSet { coverFrameView.isHidden = pageType != .cover }
    }
    @IBOutlet private weak var photobookFrameView: PhotobookFrameView!  {
        didSet { photobookFrameView.isHidden = pageType == .cover }
    }
    
    @IBOutlet private weak var photobookHorizontalAlignmentConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var coverAssetContainerView: UIView!
    @IBOutlet private weak var coverAssetImageView: UIImageView!
    @IBOutlet private weak var leftAssetContainerView: UIView!
    @IBOutlet private weak var leftAssetImageView: UIImageView!
    @IBOutlet private weak var rightAssetContainerView: UIView!
    @IBOutlet private weak var rightAssetImageView: UIImageView!
    
    private weak var assetContainerView: UIView! {
        guard let pageType = pageType else { return nil }
        
        switch pageType {
        case .left, .last:
            return leftAssetContainerView
        case .right, .first:
            return rightAssetContainerView
        case .cover:
            return coverAssetContainerView
        }
    }

    private weak var assetImageView: UIImageView! {
        guard let pageType = pageType else { return nil }
        
        switch pageType {
        case .left, .last:
            return leftAssetImageView
        case .right, .first:
            return rightAssetImageView
        case .cover:
            return coverAssetImageView
        }
    }
    
    // Public settings
    weak var delegate: PageSetupDelegate?
    var selectedAssetsManager: SelectedAssetsManager!
    var pageIndex: Int! {
        didSet {
            guard let pageIndex = pageIndex else {
                fatalError("Page editing started without a layout index")
            }
            if pageIndex == 0 { pageType = .cover }
            else if pageIndex == 1 { pageType = .first }
            else if pageIndex == ProductManager.shared.productLayouts.count - 1 { pageType = .last }
            else if pageIndex % 2 == 0 { pageType = .left }
            else { pageType = .right }
            
            productLayout = ProductManager.shared.productLayouts[pageIndex].shallowCopy()
            
            if pageIndex == 0 { // Cover
                availableLayouts = ProductManager.shared.currentCoverLayouts()
            } else {
                availableLayouts = ProductManager.shared.currentLayouts()
            }
        }
    }
    private var productLayout: ProductLayout!
    private var availableLayouts: [Layout]!
    private var pageSize: CGSize = .zero
    private var hasDoneSetup = false
    private var pageType: PageType!
    private var pageView: PhotobookPageView! {
        guard let pageType = pageType else { return nil }
        
        switch pageType {
        case .left, .last:
            return photobookFrameView.leftPageView
        case .right, .first:
            return photobookFrameView.rightPageView
        case .cover:
            return coverFrameView.pageView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbarButtons[Tools.selectAsset.rawValue].isSelected = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasDoneSetup {
            coverFrameView.color = ProductManager.shared.coverColor
            coverFrameView.pageView.aspectRatio = ProductManager.shared.product!.aspectRatio

            photobookFrameView.pageColor = ProductManager.shared.pageColor
            photobookFrameView.coverColor = ProductManager.shared.coverColor
            
            photobookFrameView.leftPageView.aspectRatio = ProductManager.shared.product!.aspectRatio
            photobookFrameView.rightPageView.aspectRatio = ProductManager.shared.product!.aspectRatio

            photobookFrameView.width = (view.bounds.width - 2.0 * Constants.photobookSideMargin) * 2.0
            
            pageView.index = pageIndex
            pageView.productLayout = productLayout            
            pageView.setupLayoutBoxes()

            setupPhotobookFrame()
            setupAssetPlacement()
            setupAssetSelection()
            setupLayoutSelection()
            hasDoneSetup = true
        }
    }
    
    private func setupPhotobookFrame() {
        switch pageType! {
        case .last:
            photobookFrameView.isRightPageVisible = false
            fallthrough
        case .left:
            photobookHorizontalAlignmentConstraint.constant = view.bounds.width - Constants.photobookSideMargin
        case .first:
            photobookFrameView.isLeftPageVisible = false
            fallthrough
        case .right:
            photobookHorizontalAlignmentConstraint.constant = Constants.photobookSideMargin
        case .cover:
            break
        }
    }
    
    private func setupAssetSelection() {
        assetSelectorViewController.selectedAssetsManager = selectedAssetsManager
        assetSelectorViewController.selectedAsset = productLayout.asset
    }
    
    private func setupLayoutSelection() {
        layoutSelectionViewController.pageIndex = pageIndex
        layoutSelectionViewController.pageType = pageType
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
    
    private func setupAssetPlacement() {
        let enabled = productLayout.layout.imageLayoutBox != nil && productLayout.asset != nil
        toolbarButtons[Tools.placeAsset.rawValue].isEnabled = enabled
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
        pageView.setupLayoutBoxes()
        
        // Deselect the asset if the layout does not have an image box
        if productLayout.layout.imageLayoutBox == nil {
            assetSelectorViewController.selectedAsset = nil
        }
        
        setupAssetPlacement()
    }
}

extension PageSetupViewController: AssetSelectorDelegate {
    
    func didSelect(asset: Asset) {
        layoutSelectionViewController.asset = asset
        productLayout.asset = asset

        // If the current layout does not have an image box, find the first layout that does and use it
        if productLayout.layout.imageLayoutBox == nil {
            let defaultLayout = availableLayouts.first(where: { $0.imageLayoutBox != nil })

            productLayout.layout = defaultLayout
            pageView.setupTextBox()
            
            layoutSelectionViewController.selectedLayout = productLayout.layout
        }

        pageView.setupImageBox()
        setupAssetPlacement()
    }
}
