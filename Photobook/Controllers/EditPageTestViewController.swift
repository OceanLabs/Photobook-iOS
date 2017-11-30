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
    
    func setupTestImage() {
        let image = UIImage(named: "LaunchImage")!
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 2.0

        let testAsset = TestAsset()
        testAsset.image = image
        
        productLayoutAsset.asset = testAsset
        productLayoutAsset.containerSize = containerView.bounds.size
        
        imageView.frame = CGRect(x: 0.0, y: 0.0, width: testAsset.size.width, height: testAsset.size.height)
        imageView.center = CGPoint(x: containerView.bounds.width / 2.0, y: containerView.bounds.height / 2.0)
        imageView.transform = productLayoutAsset.transform
        containerView.addSubview(imageView)
    }
    
    func addGestures() {
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
    
    func transformUsingRecognizer(_ recognizer: UIGestureRecognizer, transform: CGAffineTransform) -> CGAffineTransform {
        if let rotateRecognizer = recognizer as? UIRotationGestureRecognizer {
            return transform.rotated(by: rotateRecognizer.rotation)
        }
        if let pinchRecognizer = recognizer as? UIPinchGestureRecognizer {
            var scale = pinchRecognizer.scale
            
            // Makes it harder to scale down the image below 1.0
            if scale < 1.0 {
                scale = 1.4 - pow(0.4, scale)
            }
            return transform.scaledBy(x: scale, y: scale)
        }
        if let panRecognizer = recognizer as? UIPanGestureRecognizer {
            let deltaX = panRecognizer.translation(in: containerView).x
            let deltaY = panRecognizer.translation(in: containerView).y
            
            let angle = atan2(transform.b, transform.a)
            
            let tx = deltaX * cos(angle) + deltaY * sin(angle)
            let ty = -deltaX * sin(angle) + deltaY * cos(angle)

            return transform.translatedBy(x: tx, y: ty)
        }
        return transform
    }
    
    @IBAction func processTransform(_ sender: Any) {
        let gesture = sender as! UIGestureRecognizer
        
        switch gesture.state {
        case .began:
            if gestures.count == 0 { initialTransform = imageView.transform }
            gestures.insert(gesture)
        case .changed:
            if var initial = initialTransform {
                gestures.forEach({ (gesture) in initial = transformUsingRecognizer(gesture, transform: initial) })
                imageView.transform = initial
            }
        case .ended:
            gestures.remove(gesture)
            if gestures.count == 0 {
                productLayoutAsset.transform = imageView.transform
                productLayoutAsset.adjustTransform()
                
                // The keyframe animation prevents a known bug where the UI jumps when animating to a new transform
                UIView.animateKeyframes(withDuration: 0.3, delay: 0.0, options: [ .calculationModePaced ], animations: {
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
