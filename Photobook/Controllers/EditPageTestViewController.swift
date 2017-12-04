//
//  EditPageTestViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 27/11/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

class TestAsset: Asset {
    var image: UIImage!
    
    var identifier: String = "id"
    var size: CGSize {
        return CGSize(width: image.size.width, height: image.size.height)
    }
    var isLandscape: Bool {
        return size.width > size.height
    }
    func uneditedImage(size: CGSize, progressHandler: ((Int64, Int64) -> Void)?, completionHandler: @escaping (UIImage?, Error?) -> Void) {}
}

class EditPageTestViewController: UIViewController {

    @IBOutlet weak var containerView: UIView!
    var imageView = UIImageView()
    @IBOutlet weak var containerViewWidthConstraints: NSLayoutConstraint!
    @IBOutlet weak var containerViewHeightConstraints: NSLayoutConstraint!
    
    var initialTransform: CGAffineTransform?
    var gestures = Set<UIGestureRecognizer>(minimumCapacity: 3)
    var hasDoneInitialSetup = false
    
    var productLayoutAsset = ProductLayoutAsset()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        containerView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !hasDoneInitialSetup {
            setupTestImage()
            addGestures()
            hasDoneInitialSetup = true
        }
    }
    
    private func setupTestImage() {
        let image = UIImage(named: "LaunchImage")!
        imageView.image = image
        imageView.contentMode = .scaleAspectFit

        let testAsset = TestAsset()
        testAsset.image = image
        
        productLayoutAsset.asset = testAsset
        productLayoutAsset.containerSize = containerView.bounds.size
        
        imageView.frame = CGRect(x: 0.0, y: 0.0, width: testAsset.size.width, height: testAsset.size.height)
        imageView.center = CGPoint(x: containerView.bounds.width / 2.0, y: containerView.bounds.height / 2.0)
        imageView.transform = productLayoutAsset.transform
        containerView.addSubview(imageView)
    }
    
    private func addGestures() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(processTransform(_:)))
        pinchGestureRecognizer.delegate = self
        view.addGestureRecognizer(pinchGestureRecognizer)
        
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(processTransform(_:)))
        rotationGestureRecognizer.delegate = self
        view.addGestureRecognizer(rotationGestureRecognizer)
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(processTransform(_:)))
        panGestureRecognizer.delegate = self
        view.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func startedRotationGesture(_ gesture: UIRotationGestureRecognizer, inView view: UIView) {
        let location = gesture.location(in: view)
        let normalised = CGPoint(x: location.x / view.bounds.width, y: location.y / view.bounds.height)
        setAnchorPoint(anchorPoint: normalised, view: view)
    }
    
    private func setAnchorPoint(anchorPoint: CGPoint, view: UIView){
        let oldOrigin = view.frame.origin
        view.layer.anchorPoint = anchorPoint
        let newOrigin = view.frame.origin

        let transition = CGPoint(x: newOrigin.x - oldOrigin.x, y: newOrigin.y - oldOrigin.y)
        view.center = CGPoint(x: view.center.x - transition.x, y: view.center.y - transition.y)
    }
        
    @IBAction func processTransform(_ sender: Any) {
        let gesture = sender as! UIGestureRecognizer
        
        switch gesture.state {
        case .began:
            if gestures.count == 0 { initialTransform = imageView.transform }
            gestures.insert(gesture)
            if let gesture = gesture as? UIRotationGestureRecognizer {
                startedRotationGesture(gesture, inView: imageView)
            }
        case .changed:
            if var initial = initialTransform {
                gestures.forEach({ (gesture) in initial = LayoutUtils.adjustTransform(initial, withRecognizer: gesture, inParentView: containerView) })
                imageView.transform = initial
            }
        case .ended:
            gestures.remove(gesture)
            if gestures.count == 0 {
                setAnchorPoint(anchorPoint: CGPoint(x: 0.5, y: 0.5), view: imageView)
                
                imageView.transform = LayoutUtils.centerTransform(imageView.transform, inParentView: containerView, fromPoint: imageView.center)
                imageView.center = CGPoint(x: containerView.bounds.midX, y: containerView.bounds.midY)
                
                productLayoutAsset.transform = imageView.transform
                productLayoutAsset.adjustTransform()

                // The keyframe animation prevents a known bug where the UI jumps when animating to a new transform
                UIView.animateKeyframes(withDuration: 0.2, delay: 0.0, options: [ .calculationModeCubicPaced ], animations: {
                    UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 1.0, animations: {
                        self.imageView.transform = self.productLayoutAsset.transform
                    })
                }, completion: nil)
            }
        default:
            break
        }
    }
}

extension EditPageTestViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
}
