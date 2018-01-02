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
        if let productLayoutAsset = productLayout?.productLayoutAsset {
            let transform = productLayoutAsset.transform
            let angle = atan2(transform.b, transform.a)
            let rotateTo = LayoutUtils.nextCCWCuadrantAngle(to: angle)
            
            let scale = LayoutUtils.scaleToFill(containerSize: imageBoxView.bounds.size, withSize: productLayoutAsset.asset!.size, atAngle: rotateTo)
            productLayoutAsset.transform = CGAffineTransform.identity.rotated(by: rotateTo).scaledBy(x: scale, y: scale)
            UIView.animateKeyframes(withDuration: 0.3, delay: 0.0, options: [ .calculationModeCubicPaced ], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0, animations: {
                    self.assetImageView.transform = productLayoutAsset.transform
                })
            }, completion: nil)
        }
    }
    
    // MARK: User interaction
    var initialTransform: CGAffineTransform?
    var gestures = Set<UIGestureRecognizer>(minimumCapacity: 3)

    private func startedRotationGesture(_ gesture: UIRotationGestureRecognizer, inView view: UIView) {
        let location = gesture.location(in: view)
        let normalised = CGPoint(x: location.x / view.bounds.width, y: location.y / view.bounds.height)
        setAnchorPoint(anchorPoint: normalised, view: view)
    }

    private func setAnchorPoint(anchorPoint: CGPoint, view: UIView) {
        let oldOrigin = view.frame.origin
        view.layer.anchorPoint = anchorPoint
        let newOrigin = view.frame.origin
        
        let transition = CGPoint(x: newOrigin.x - oldOrigin.x, y: newOrigin.y - oldOrigin.y)
        view.center = CGPoint(x: view.center.x - transition.x, y: view.center.y - transition.y)
    }

    @IBAction func processTransform(_ gesture: UIGestureRecognizer) {
        guard let productLayoutAsset = productLayout?.productLayoutAsset else { return }
        
        switch gesture.state {
        case .began:
            if gestures.count == 0 { initialTransform = assetImageView.transform }
            gestures.insert(gesture)
            if let gesture = gesture as? UIRotationGestureRecognizer {
                startedRotationGesture(gesture, inView: assetImageView)
            }
        case .changed:
            if var initial = initialTransform {
                gestures.forEach({ (gesture) in initial = LayoutUtils.adjustTransform(initial, withRecognizer: gesture, inParentView: imageBoxView) })
                assetImageView.transform = initial
            }
        case .ended:
            gestures.remove(gesture)
            if gestures.count == 0 {
                setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5), view: assetImageView)
                
                assetImageView.transform = LayoutUtils.centerTransform(assetImageView.transform, inParentView: imageBoxView, fromPoint: assetImageView.center)
                assetImageView.center = CGPoint(x: imageBoxView.bounds.midX, y: imageBoxView.bounds.midY)
                
                productLayoutAsset.transform = assetImageView.transform
                productLayoutAsset.adjustTransform()
                
                // The keyframe animation prevents a known bug where the UI jumps when animating to a new transform
                UIView.animateKeyframes(withDuration: 0.2, delay: 0.0, options: [ .calculationModeCubicPaced ], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0, animations: {
                        self.assetImageView.transform = productLayoutAsset.transform
                    })
                }, completion: nil)
            }
        default:
            break
        }
    }
}

extension AssetPlacementViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
