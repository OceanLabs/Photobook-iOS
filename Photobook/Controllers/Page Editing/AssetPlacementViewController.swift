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
    
    @IBOutlet private weak var assetContainerView: UIView!
    @IBOutlet private weak var assetImageView: UIImageView!
    @IBOutlet private weak var assetContainerViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var assetContainerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var assetEditingAreaView: UIView!

    private lazy var animatableAssetImageView = UIImageView()
    
    // Public vars
    var productLayout: ProductLayout?
    var initialContainerRect: CGRect?
    var targetRect: CGRect?
    var assetImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.alpha = 0.0
    }
    
    func animateFromPhotobook() {
        guard let productLayout = productLayout,
            let containerSize = productLayout.productLayoutAsset?.containerSize else { return }
        
        setUpLayoutImageBox(withRatio: containerSize.height / containerSize.width)
        setUpImageView(withProductLayout: productLayout)

        guard let initialContainerRect = initialContainerRect else {
            view.alpha = 1.0
            return
        }
        
        let backgroundColor = view.backgroundColor
        view.backgroundColor = .clear
        
        assetEditingAreaView.layoutIfNeeded()
        assetEditingAreaView.alpha = 0.0
        
        targetRect = assetEditingAreaView.convert(assetContainerView.frame, to: view)
        animatableAssetImageView.transform = .identity
        animatableAssetImageView.frame = targetRect!
        animatableAssetImageView.image = assetContainerView.snapshot()
        animatableAssetImageView.center = CGPoint(x: initialContainerRect.midX, y: initialContainerRect.midY)
        
        let initialScale = initialContainerRect.width / targetRect!.width
        animatableAssetImageView.transform = CGAffineTransform.identity.scaledBy(x: initialScale, y: initialScale)
        
        view.addSubview(animatableAssetImageView)
        view.alpha = 1.0
        
        UIView.animate(withDuration: 0.1, delay: 0.2, options: [.curveEaseInOut], animations: {
            self.assetEditingAreaView.alpha = 1.0
        }, completion: { _ in
            self.animatableAssetImageView.alpha = 0.0
        })

        UIView.animate(withDuration: 0.3, animations: {
            self.view.backgroundColor = backgroundColor
            self.animatableAssetImageView.frame = self.targetRect!
        })
    }
    
    func animateBackToPhotobook(_ completion: @escaping (() -> Void)) {
        guard let initialContainerRect = initialContainerRect,
              let productLayoutAsset = productLayout?.productLayoutAsset else {
            view.alpha = 0.0
            return
        }

        // Re-calculate transform for the photobook's container size
        productLayoutAsset.containerSize = CGSize(width: initialContainerRect.width, height: initialContainerRect.height)

        animatableAssetImageView.image = assetContainerView.snapshot()
        animatableAssetImageView.alpha = 1.0
        
        let backgroundColor = view.backgroundColor
        
        UIView.animate(withDuration: 0.1, animations: {
            self.assetEditingAreaView.alpha = 0.0
        })

        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.view.backgroundColor = .clear
            self.animatableAssetImageView.frame = initialContainerRect
        }, completion: { _ in
            self.view.alpha = 0.0
            self.view.backgroundColor = backgroundColor
            completion()
        })
    }
    
    private func setUpLayoutImageBox(withRatio ratio: CGFloat) {
        // Calculate new container size
        var width: CGFloat
        var height: CGFloat
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
        
        assetContainerViewWidthConstraint.constant = floor(width)
        assetContainerViewHeightConstraint.constant = floor(height)
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
        productLayout.productLayoutAsset?.containerSize = CGSize(width: assetContainerViewWidthConstraint.constant, height: assetContainerViewHeightConstraint.constant)
        assetImageView.transform = productLayout.productLayoutAsset!.transform
        assetImageView.center = CGPoint(x: assetContainerViewWidthConstraint.constant * 0.5, y: assetContainerViewHeightConstraint.constant * 0.5)
        
        assetImageView.image = assetImage
    }
    
    @IBAction private func tappedRotateButton(_ sender: UIButton) {
        if let productLayoutAsset = productLayout?.productLayoutAsset {
            let transform = productLayoutAsset.transform
            let angle = atan2(transform.b, transform.a)
            let rotateTo = LayoutUtils.nextCCWCuadrantAngle(to: angle)
            
            let scale = LayoutUtils.scaleToFill(containerSize: assetContainerView.bounds.size, withSize: productLayoutAsset.asset!.size, atAngle: rotateTo)
            productLayoutAsset.transform = CGAffineTransform.identity.rotated(by: rotateTo).scaledBy(x: scale, y: scale)
            UIView.animateKeyframes(withDuration: 0.3, delay: 0.0, options: [ .calculationModeCubicPaced ], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0, animations: {
                    self.assetImageView.transform = productLayoutAsset.transform
                })
            }, completion: nil)
        }
    }
    
    // MARK: User interaction
    private var initialTransform: CGAffineTransform?
    private var gestures = Set<UIGestureRecognizer>(minimumCapacity: 3)

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
            if gestures.isEmpty { initialTransform = assetImageView.transform }
            gestures.insert(gesture)
            if let gesture = gesture as? UIRotationGestureRecognizer {
                startedRotationGesture(gesture, inView: assetImageView)
            }
        case .changed:
            if var initial = initialTransform {
                gestures.forEach({ (gesture) in initial = LayoutUtils.adjustTransform(initial, withRecognizer: gesture, inParentView: assetContainerView) })
                assetImageView.transform = initial
            }
        case .ended:
            gestures.remove(gesture)
            if gestures.isEmpty {
                setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5), view: assetImageView)
                
                assetImageView.transform = LayoutUtils.centerTransform(assetImageView.transform, inParentView: assetContainerView, fromPoint: assetImageView.center)
                assetImageView.center = CGPoint(x: assetContainerView.bounds.midX, y: assetContainerView.bounds.midY)
                
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
