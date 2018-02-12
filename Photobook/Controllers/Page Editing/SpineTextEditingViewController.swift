//
//  SpineTextEditingViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 08/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class SpineTextEditingViewController: UIViewController {

    @IBOutlet private weak var spineContainerView: UIView!
    @IBOutlet private weak var spineFrameView: SpineFrameView!
    @IBOutlet private weak var textViewBorderView: UIView!
    @IBOutlet private weak var textView: UITextView! {
        didSet {
            textView.textContainer.maximumNumberOfLines = 1
            textView.textContainer.lineBreakMode = .byTruncatingTail
        }
    }
    @IBOutlet private weak var textToolBarView: TextToolBarView! {
        didSet { textToolBarView.delegate = self }
    }
    
    @IBOutlet private weak var spineFrameViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var spineFrameViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var spineFrameViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var textViewHeightConstraint: NSLayoutConstraint!
    
    // TEMP
    private struct Constants {
        static let spineThickness: CGFloat = 20.0
        static let spineTextPadding: CGFloat = 100.0
        static let fontType: FontType = .cover
        
        static let textViewPadding: CGFloat = 16.0
    }
    
    var spineText: String?
    var coverColor: ProductColor!
    var initialRect: CGRect!
    
    private lazy var animatableSpineImageView = UIImageView()
    private var backgroundColor: UIColor!
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        let navigationBar = navigationController?.navigationBar as? PhotobookNavigationBar
        navigationBar?.setBarType(.clear)
        
        // Calculate view rects
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        textView.textContainer.lineFragmentPadding = 0.0
        textView.textContainerInset = .zero

        textView.becomeFirstResponder()
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            // Code placed here animate along with the keyboard, hence the closure
            UIView.performWithoutAnimation {
                spineFrameViewBottomConstraint.constant = keyboardSize.height // Give the cover some more room so it does not touch the keyboard top
                
                DispatchQueue.main.async {
                    self.performAnimations()
                }
            }
        }
    }
    
    private func performAnimations() {
        UIView.animate(withDuration: 0.1) {
            self.view.backgroundColor = self.backgroundColor
        }

        UIView.animate(withDuration: 0.6, delay: 0.1, options: [.curveEaseInOut], animations: {
            self.animatableSpineImageView.center = self.spineContainerView.convert(self.spineFrameView.center, to: self.view)
            self.animatableSpineImageView.transform = CGAffineTransform(rotationAngle: .pi / 2.0)
        }, completion: { _ in
            self.animatableSpineImageView.alpha = 0.0
            self.spineFrameView.alpha = 1.0
            self.spineFrameView.transform = CGAffineTransform(rotationAngle: .pi / 2.0)
            
            UIView.animate(withDuration: 0.1) {
                self.textViewBorderView.alpha = 1.0
                self.textView.alpha = 1.0
            }
        })
    }
    
    private func setup() {
        textView.inputAccessoryView = textToolBarView
        textView.text = spineText

        let paddingRatio = Constants.spineTextPadding / ProductManager.shared.product!.pageHeight
        let initialContainerRatio = initialRect.width / initialRect.height
        
        // Figure out the size of the spine frame
        let height = textView.bounds.width * (1.0 + paddingRatio * 2.0)
        let width = height * initialContainerRatio
        
        spineFrameViewWidthConstraint.constant = width
        spineFrameViewHeightConstraint.constant = height
        spineFrameView.resetSpineColor()
        
        spineFrameView.spineText = spineText
        
        textViewHeightConstraint.constant = width - Constants.textViewPadding // since the cover will be on its side
        
        // FIXME: Set style from product manager
        setTextViewAttributes(with: Constants.fontType, fontColor: coverColor.fontColor())
        
        textViewBorderView.alpha = 0.0
        textView.alpha = 0.0
        
        backgroundColor = view.backgroundColor
        view.backgroundColor = .clear
        view.alpha = 1.0
        
        spineContainerView.layoutIfNeeded()
        
        // Take a view snapshot and shrink it to the initial frame
        animatableSpineImageView.transform = .identity
        animatableSpineImageView.frame = spineContainerView.convert(spineFrameView.frame, to: view)
        animatableSpineImageView.image = spineFrameView.snapshot()
        animatableSpineImageView.center = CGPoint(x: initialRect.midX, y: initialRect.midY)
        
        let initialScale = initialRect.height / spineFrameView.bounds.height
        animatableSpineImageView.transform = CGAffineTransform.identity.scaledBy(x: initialScale, y: initialScale)
        
        view.addSubview(animatableSpineImageView)
        spineFrameView.alpha = 0.0
    }
    
    // FIXME: Add to extension
    private func onScreenFontSize(for fontType: FontType) -> CGFloat {
        let photobookToOnScreenScale = textViewHeightConstraint.constant / Constants.spineThickness
        return round(fontType.photobookFontSize() * photobookToOnScreenScale)
    }

    private func setTextViewAttributes(with fontType: FontType, fontColor: UIColor) {
        let fontSize = onScreenFontSize(for: fontType)
        textView.attributedText = fontType.attributedText(with: textView.text, fontSize: fontSize, fontColor: fontColor)
        textView.typingAttributes = fontType.typingAttributes(fontSize: fontSize, fontColor: fontColor)
    }
    
    @IBAction func tappedCancelButton(_ sender: UIBarButtonItem) {
        // FIXME: Add to delegate
        dismiss(animated: false, completion: nil)
    }
    
    @IBAction func tappedDoneButton(_ sender: UIBarButtonItem) {
    }
}


extension SpineTextEditingViewController: TextToolBarViewDelegate {
    
    func didSelectFontType(_ fontType: FontType) {
//        setTextViewAttributes(with: fontType, fontColor: pageColor.fontColor())
//
//        delegate?.didChangeFontType(to: fontType)
    }
}

