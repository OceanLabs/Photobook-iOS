//
//  PageSetupViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 13/12/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

protocol PageSetupDelegate: class {
    func didFinishEditingPage(_ index: Int?, productLayout: ProductLayout?, color: ProductColor?)
}

extension PageSetupDelegate {
    func didFinishEditingPage(_ index: Int? = nil, productLayout: ProductLayout? = nil, color: ProductColor? = nil) {
        didFinishEditingPage(index, productLayout: productLayout, color: color)
    }
}

enum PageType {
    case cover, first, last, left, right
}

class PageSetupViewController: UIViewController, PhotobookNavigationBarDelegate {

    private struct Constants {
        static let photobookSideMargin: CGFloat = 20.0
    }
    
    private enum Tool: Int {
        case selectAsset, selectLayout, placeAsset, selectColor, editText
    }
    
    @IBOutlet private weak var photobookContainerView: UIView!
    @IBOutlet private weak var assetSelectionContainerView: UIView!
    @IBOutlet private weak var layoutSelectionContainerView: UIView!
    @IBOutlet private weak var placementContainerView: UIView!
    @IBOutlet private weak var colorSelectionContainerView: UIView!
    @IBOutlet private weak var textEditingContainerView: UIView!
    
    @IBOutlet var toolbarButtons: [UIButton]!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var photobookNavigationBarType: PhotobookNavigationBarType = .clear
    
    private var assetSelectorViewController: AssetSelectorViewController!
    private var layoutSelectionViewController: LayoutSelectionViewController!
    private var assetPlacementViewController: AssetPlacementViewController!
    private var colorSelectionViewController: ColorSelectionViewController!
    private var textEditingViewController: TextEditingViewController!
    
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
    private var pageType: PageType! {
        didSet {
            if pageType == .cover {
                selectedColor = ProductManager.shared.coverColor
            } else {
                selectedColor = ProductManager.shared.pageColor
            }
        }
    }
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
    private var selectedColor: ProductColor!
    private var pageColor = ProductManager.shared.pageColor
    
    private var previouslySelectedButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        toolbarButtons[Tool.selectAsset.rawValue].isSelected = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasDoneSetup {
            textEditingContainerView.alpha = 0.0
            
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
            setupColorSelection()
            setupTextEditing()
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
        layoutSelectionViewController.coverColor = ProductManager.shared.coverColor
        layoutSelectionViewController.pageColor = ProductManager.shared.pageColor
    }
    
    private func setupColorSelection() {
        colorSelectionViewController.selectedColor = selectedColor
    }
    
    private func setupTextEditing() {
        let enabled = productLayout.layout.textLayoutBox != nil
        toolbarButtons[Tool.editText.rawValue].isEnabled = enabled
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
        case "ColorSelectionSegue":
            colorSelectionViewController = segue.destination as! ColorSelectionViewController
            colorSelectionViewController.delegate = self
        case "TextEditingSegue":
            textEditingViewController = segue.destination as! TextEditingViewController
            textEditingViewController.delegate = self
        default:
            break
        }
    }
    
    private func setupAssetPlacement() {
        let enabled = productLayout.layout.imageLayoutBox != nil && productLayout.asset != nil
        toolbarButtons[Tool.placeAsset.rawValue].isEnabled = enabled
    }
    
    @IBAction func tappedCancelButton(_ sender: UIBarButtonItem) {
        delegate?.didFinishEditingPage()
    }
    
    @IBAction func tappedDoneButton(_ sender: UIBarButtonItem) {
        if productLayout.layout.imageLayoutBox == nil {
            // Remove the asset if the layout doesn't have an image box
            productLayout.asset = nil
        }
        delegate?.didFinishEditingPage(pageIndex, productLayout: productLayout, color: selectedColor)
    }
    
    @IBAction func tappedToolButton(_ sender: UIButton) {
        
        guard let index = toolbarButtons.index(of: sender),
            !toolbarButtons[index].isSelected,
            let tool = Tool(rawValue: index) else { return }

        // Store currently selected tool so we may come back to it
        previouslySelectedButton = toolbarButtons.first { $0.isSelected }
        
        let editLayoutWasSelected = toolbarButtons[Tool.placeAsset.rawValue].isSelected
        
        for button in toolbarButtons { button.isSelected = (button === sender) }
        
        switch tool {
        case .selectAsset, .selectLayout, .selectColor:
            if editLayoutWasSelected {
                assetPlacementViewController.animateBackToPhotobook {
                    self.assetImageView.transform = self.productLayout!.productLayoutAsset!.transform
                    self.view.sendSubview(toBack: self.placementContainerView)
                }
            }
            
            UIView.animate(withDuration: 0.1, animations: {
                self.photobookContainerView.alpha = 1.0
                self.textEditingContainerView.alpha = 0.0
                self.assetSelectionContainerView.alpha = tool.rawValue == Tool.selectAsset.rawValue ? 1.0 : 0.0
                self.layoutSelectionContainerView.alpha = tool.rawValue == Tool.selectLayout.rawValue ? 1.0 : 0.0
                self.colorSelectionContainerView.alpha = tool.rawValue == Tool.selectColor.rawValue ? 1.0 : 0.0
            })
        case .placeAsset:
            view.bringSubview(toFront: placementContainerView)
            
            let containerRect = placementContainerView.convert(assetContainerView.frame, from: pageView)
            assetPlacementViewController.productLayout = productLayout
            assetPlacementViewController.initialContainerRect = containerRect
            assetPlacementViewController.assetImage = assetImageView.image
            assetPlacementViewController.animateFromPhotobook()
        case .editText:
            view.bringSubview(toFront: textEditingContainerView)
            
            // TODO: Animate photobook
            textEditingViewController.productLayout = productLayout!
            textEditingViewController.assetImage = assetImageView.image
            textEditingViewController.pageColor = selectedColor
            textEditingViewController.setup()
            
            UIView.animate(withDuration: 0.2, animations: {
                self.assetSelectionContainerView.alpha = 0.0
                self.layoutSelectionContainerView.alpha = 0.0
                self.colorSelectionContainerView.alpha = 0.0
                self.photobookContainerView.alpha = 0.0
                self.textEditingContainerView.alpha = 1.0
            })
        }
        
        setTopBars(hidden: tool == .editText)
    }
    
    private func setTopBars(hidden: Bool) {
        navigationController?.setNavigationBarHidden(hidden, animated: true)
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool {
        return toolbarButtons != nil ? toolbarButtons[Tool.editText.rawValue].isSelected : false
    }
}

extension PageSetupViewController: LayoutSelectionDelegate {
    
    func didSelectLayout(_ layout: Layout) {
        productLayout.layout = layout
        pageView.setupLayoutBoxes()
        
        // Deselect the asset if the layout does not have an image box
        if productLayout.layout.imageLayoutBox == nil {
            assetSelectorViewController.selectedAsset = nil
        } else if productLayout.asset != nil && assetSelectorViewController.selectedAsset == nil {
            assetSelectorViewController.reselectAsset(productLayout.asset!)
        }
        
        setupAssetPlacement()
        setupTextEditing()
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

extension PageSetupViewController: ColorSelectorDelegate {
    
    func didSelect(_ color: ProductColor) {
        selectedColor = color
        
        if pageType == .cover {
            coverFrameView.color = color
            coverFrameView.resetCoverColor()
            
            layoutSelectionViewController.coverColor = color
        } else {
            photobookFrameView.pageColor = color
            photobookFrameView.resetPageColor()
            
            layoutSelectionViewController.pageColor = color
        }
        
    }
}

extension PageSetupViewController: TextEditingDelegate {
    
    func didChangeText(to text: String?) {
        productLayout.text = text
        pageView.setupTextBox()
        tappedToolButton(previouslySelectedButton)
    }
    
    func didChangeFontType(to fontType: FontType) {
        productLayout.fontType = fontType
        pageView.setupTextBox()
    }
}
