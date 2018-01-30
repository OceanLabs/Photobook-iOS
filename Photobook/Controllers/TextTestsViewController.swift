//
//  TextTestsViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 29/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class TextTestsViewController: UIViewController {
    @IBOutlet weak var photobookPageView: UIView!
    @IBOutlet weak var photobookPageHeight: NSLayoutConstraint!
    @IBOutlet weak var textLayoutBox: UILabel!
    
    @IBOutlet weak var textViewTestLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var textViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var pageHeightTextField: UITextField!
    @IBOutlet weak var fontSizeTextField: UITextField!
    @IBOutlet weak var textViewHeightTextField: UITextField!
    
    private var layoutBox: LayoutBox!
    private var availableWidth: CGFloat!
    
    private let text = "This is what text would look like if the user was typing in the layout box."
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        availableWidth = view.bounds.width - 40.0
        
        photobookPageHeight.constant = textViewWidthConstraint.constant / 1.38157681
        
        textView.textContainer.lineFragmentPadding = 0.0
        textView.textContainerInset = .zero
        textView.delegate = self
    
        adjustText(self)
    }
    
    private func calculateFontSize(photobookHeight: CGFloat, containerHeight: CGFloat, fontSize: CGFloat) -> CGFloat {
        let onScreenRatio = containerHeight / photobookHeight
        
        let newFontSize = round(fontSize * onScreenRatio)
        return newFontSize
    }
    
    @IBAction func adjustText(_ sender: Any) {
        
        guard
            let textViewHeightString = textViewHeightTextField.text,
            let textViewHeightNumber = NumberFormatter().number(from: textViewHeightString),

            let fontSizeString = fontSizeTextField.text,
            let fontSizeNumber = NumberFormatter().number(from: fontSizeString),

            let pageHeightString = pageHeightTextField.text,
            let pageHeightNumber = NumberFormatter().number(from: pageHeightString) else {

                return
        }
        
        // Layout box percent height
        let textViewHeight = CGFloat(truncating: textViewHeightNumber)
        
        // Font size relative to the height of the page in pt
        let fontSize = CGFloat(truncating: fontSizeNumber)
        
        // Height of the page in pt
        let pageHeight = CGFloat(truncating: pageHeightNumber)
    
        layoutBox = LayoutBox(id: 0, rect: CGRect(x: 0.0833389329391211, y: 0.748346368974401, width: 0.312491600591318, height: textViewHeight))
        
        // Get layout box frame and centre
        let finalFrame = layoutBox.rectContained(in: CGSize(width: textViewWidthConstraint.constant, height: photobookPageHeight.constant))
        let finalCentre = CGPoint(x: finalFrame.midX, y: finalFrame.midY)
        
        // Multiply frame size by a fixed scale, then shrink back the transform by the same scale
        let scale: CGFloat = 1.55
        let fakeSize = CGSize(width: finalFrame.width * scale, height: finalFrame.height * scale)
        textLayoutBox.transform = .identity
        textLayoutBox.frame = CGRect(x: finalFrame.minX, y: finalFrame.minY, width: finalFrame.width * scale, height: finalFrame.height * scale)
        textLayoutBox.center = finalCentre
        
        let layoutContainerSize = layoutBox.containerSize(for: fakeSize)
        
        textLayoutBox.transform = textLayoutBox.transform.scaledBy(x: 1/scale, y: 1/scale)
        
        let pbFontSize = calculateFontSize(photobookHeight: pageHeight, containerHeight: layoutContainerSize.height, fontSize: fontSize)
        
        //let pbFontSize = calculateFontSize(photobookHeight: pageHeight, containerHeight: photobookPageHeight.constant, fontSize: fontSize)
        //textLayoutBox.font = UIFont(name: "Helvetica", size: pbFontSize)
        textLayoutBox.attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.font: UIFont(name: "Helvetica", size: pbFontSize)!])
    
        let layoutBoxAspectRatio = textLayoutBox.frame.width / textLayoutBox.frame.height
        
        let textBoxHeight = availableWidth / layoutBoxAspectRatio
        textViewHeightConstraint.constant = textBoxHeight
        
        let containerSize = layoutBox.containerSize(for: CGSize(width: availableWidth, height: textBoxHeight))

        let newFontSize = calculateFontSize(photobookHeight: pageHeight, containerHeight: containerSize.height, fontSize: fontSize)
        
        textView.attributedText = NSAttributedString(string: text, attributes: [NSAttributedStringKey.font: UIFont(name: "Helvetica", size: newFontSize)!])
        textViewTestLabel.attributedText = textView.attributedText
    }
}

extension TextTestsViewController: UITextViewDelegate {
    
    func textViewDidChange(_ textView: UITextView) {
        textView.scrollRangeToVisible(NSMakeRange(textView.text.count, 0))
        textView.scrollRectToVisible(textView.caretRect(for: textView.endOfDocument), animated: false)
    }
}
