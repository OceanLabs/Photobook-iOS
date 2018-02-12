//
//  SpineTextEditingViewController.swift
//  Photobook
//
//  Created by Jaime Landazuri on 08/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol SpineTextEditingDelegate: class {
    func didCancelSpineTextEditing(_ spineTextEditingViewController: SpineTextEditingViewController)
    func didSaveSpineTextEditing(_ spineTextEditingViewController: SpineTextEditingViewController, spineText: String?, fontType: FontType)
}

class SpineTextEditingViewController: UIViewController {

    @IBOutlet private weak var spineContainerView: UIView!
    @IBOutlet private weak var spineFrameView: SpineFrameView!
    @IBOutlet private weak var textViewBorderView: UIView!
    @IBOutlet private weak var textView: PhotobookTextView! {
        didSet {
            textView.textContainer.maximumNumberOfLines = 1
            textView.textContainer.lineBreakMode = .byTruncatingTail
        }
    }
    @IBOutlet private weak var textToolBarView: TextToolBarView! {
        didSet { textToolBarView.delegate = self }
    }
    @IBOutlet private var cancelButton: UIBarButtonItem!
    @IBOutlet private var doneButton: UIBarButtonItem!
    
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
    
    var initialRect: CGRect!
    weak var delegate: SpineTextEditingDelegate?
    
    private lazy var animatableSpineImageView = UIImageView()
    private var backgroundColor: UIColor!
    private var initialTransform: CGAffineTransform!
    
    private var fontType: FontType = ProductManager.shared.spineFontType
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: .UIKeyboardWillShow, object: nil)
        
        let navigationBar = navigationController?.navigationBar as? PhotobookNavigationBar
        navigationBar?.setBarType(.clear)

        navigationItem.setLeftBarButton(nil, animated: false)
        navigationItem.setRightBarButton(nil, animated: false)
        
        // Calculate view rects
        setup()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationItem.setLeftBarButton(cancelButton, animated: true)
        navigationItem.setRightBarButton(doneButton, animated: true)
        
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

        UIView.animateKeyframes(withDuration: 0.4, delay: 0, options: .calculationModePaced, animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1.0, animations: {
                self.animatableSpineImageView.center = self.spineContainerView.convert(self.spineFrameView.center, to: self.view)
                self.animatableSpineImageView.transform = CGAffineTransform(rotationAngle: .pi / 2.0)
            })
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
    
    func animateOff(completion: @escaping () -> Void) {
        let backgroundColor = view.backgroundColor
        
        textView.resignFirstResponder()
        
        textView.alpha = 0.0
        textViewBorderView.alpha = 0.0
        
        spineFrameView.alpha = 0.0
        animatableSpineImageView.alpha = 1.0
        
        navigationItem.setLeftBarButton(nil, animated: true)
        navigationItem.setRightBarButton(nil, animated: true)
        
        UIView.animate(withDuration: 0.36, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.animatableSpineImageView.center = CGPoint(x: self.initialRect.midX, y: self.initialRect.midY)
            self.animatableSpineImageView.transform = self.initialTransform
        }, completion: { _ in
            UIView.animate(withDuration: 0.14, delay: 0.0, options: [], animations: {
                self.view.backgroundColor = .clear
            }, completion: { _ in
                self.view.alpha = 0.0
                self.view.backgroundColor = backgroundColor
                completion()
            })
        })
    }
    
    private func setup() {
        textView.inputAccessoryView = textToolBarView
        textView.text = ProductManager.shared.spineText

        let paddingRatio = Constants.spineTextPadding / ProductManager.shared.product!.pageHeight
        let initialContainerRatio = initialRect.width / initialRect.height
        
        // Figure out the size of the spine frame
        let height = textView.bounds.width * (1.0 + paddingRatio * 2.0)
        let width = height * initialContainerRatio
        
        spineFrameViewWidthConstraint.constant = width
        spineFrameViewHeightConstraint.constant = height
        spineFrameView.resetSpineColor()
        
        textViewHeightConstraint.constant = width - Constants.textViewPadding // since the cover will be on its side
        
        setTextViewAttributes(with: Constants.fontType, fontColor: ProductManager.shared.coverColor.fontColor())
        
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
        initialTransform = CGAffineTransform.identity.scaledBy(x: initialScale, y: initialScale)
        animatableSpineImageView.transform = initialTransform
        
        animatableSpineImageView.layer.shadowColor = spineFrameView.layer.shadowColor
        animatableSpineImageView.layer.shadowOffset = spineFrameView.layer.shadowOffset
        animatableSpineImageView.layer.shadowOpacity = spineFrameView.layer.shadowOpacity
        animatableSpineImageView.layer.shadowRadius = spineFrameView.layer.shadowRadius

        view.addSubview(animatableSpineImageView)
        spineFrameView.alpha = 0.0
    }
    
    private func setTextViewAttributes(with fontType: FontType, fontColor: UIColor) {
        let fontSize = fontType.sizeForScreenHeight(spineFrameViewHeightConstraint.constant)
        textView.attributedText = fontType.attributedText(with: textView.text, fontSize: fontSize, fontColor: fontColor)
        textView.typingAttributes = fontType.typingAttributes(fontSize: fontSize, fontColor: fontColor)
    }
    
    @IBAction func tappedCancelButton(_ sender: UIBarButtonItem) {
        delegate?.didCancelSpineTextEditing(self)
    }
    
    @IBAction func tappedDoneButton(_ sender: UIBarButtonItem) {
        delegate?.didSaveSpineTextEditing(self, spineText: textView.text, fontType: fontType)
    }
}

extension SpineTextEditingViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let textView = textView as! PhotobookTextView
        
        // Dismiss on line break
        guard text.rangeOfCharacter(from: CharacterSet.newlines) == nil else {
            textView.resignFirstResponder()
            delegate?.didSaveSpineTextEditing(self, spineText: textView.text, fontType: fontType)
            return false
        }

        return textView.shouldChangePhotobookText(in: range, replacementText: text)
    }
}

extension SpineTextEditingViewController: TextToolBarViewDelegate {
    
    func didSelectFontType(_ fontType: FontType) {
        setTextViewAttributes(with: fontType, fontColor: ProductManager.shared.coverColor.fontColor())
        self.fontType = fontType
    }
}
