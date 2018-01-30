//
//  TextEditingViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 30/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class TextToolBarView: UIView {
    
    // TODO: Configure with product colour
    
}

class TextEditingViewController: UIViewController {

    private struct Constants {
        static let textViewBorderPadding: CGFloat = 12.0 // 8.0 padding, 4.0 thickness
    }
    
    @IBOutlet private weak var textToolBarView: TextToolBarView! {
        didSet {
            textToolBarView.backgroundColor = UIColor(red: 208/255.0, green: 212/255.0, blue: 217/255.0, alpha: 1.0)
        }
    }
    @IBOutlet private weak var textViewBorderView: UIView!
    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var pageView: UIView!
    @IBOutlet private weak var imageContainerView: UIView!
    @IBOutlet private weak var assetImageView: UIImageView!
    
    @IBOutlet private weak var textViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textViewBottomConstraint: NSLayoutConstraint!
    
    var productLayout: ProductLayout? {
        didSet {
            textView.inputAccessoryView = textToolBarView
            textView.becomeFirstResponder()
            setupPage()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // FIXME: Move color to global scope
        textViewBorderView.borderColor = UIColor(red: 0.0, green: 0.48, blue: 1.0, alpha: 1.0)
        textView.textContainer.lineFragmentPadding = 0.0
        textView.textContainerInset = .zero
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            textViewBottomConstraint.constant = keyboardSize.height + Constants.textViewBorderPadding
        }
    }

    private func setupPage() {
        // Figure out the height of the textView
        guard
            let pageRatio = ProductManager.shared.product?.aspectRatio,
            let layoutBox = productLayout?.layout.textLayoutBox
        else {
            fatalError("Text editing failed due to missing layout info.")
        }
        
        let aspectRatio = layoutBox.aspectRatio(forContainerRatio: pageRatio)
        textViewHeightConstraint.constant = textViewWidthConstraint.constant / aspectRatio
        
        // Position page and image box, if needed
        let layoutBoxSize = CGSize(width: textViewWidthConstraint.constant, height: textViewHeightConstraint.constant)
        let pageSize = layoutBox.containerSize(for: layoutBoxSize)
        
        print("BC \(textViewBottomConstraint.constant)")
        let topMargin = view.bounds.height - textViewBottomConstraint.constant - textViewHeightConstraint.constant
        let layoutBoxRect = layoutBox.rectContained(in: pageSize)
        let pageXCoordinate = textViewLeadingConstraint.constant - layoutBoxRect.minX
        let pageYCoordinate = topMargin - layoutBoxRect.minY
        
        pageView.frame.origin = CGPoint(x: pageXCoordinate, y: pageYCoordinate)
        pageView.frame.size = pageSize
        
        // Place image if needed
        
    }
}
