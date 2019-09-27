//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
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
    
    @IBOutlet private weak var textField: UITextField!
    @IBOutlet private weak var textToolBarView: TextToolBarView! {
        didSet { textToolBarView.delegate = self }
    }
    @IBOutlet private var cancelButton: UIBarButtonItem!
    @IBOutlet private var doneButton: UIBarButtonItem!
    
    @IBOutlet private weak var spineFrameViewWidthConstraint: NSLayoutConstraint!
    @IBOutlet private weak var spineFrameViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var spineFrameViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet private weak var textFieldHeightConstraint: NSLayoutConstraint!

    private struct Constants {
        static let textFieldSafetyPadding: CGFloat = 4.0
    }
    
    var initialRect: CGRect!
    weak var delegate: SpineTextEditingDelegate?
    
    private lazy var animatableSpineImageView = UIImageView()
    private var backgroundColor: UIColor!
    private var initialTransform: CGAffineTransform!
    
    private lazy var fontType: FontType = product.spineFontType
    
    private var product: PhotobookProduct! {
        return ProductManager.shared.currentProduct
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Analytics.shared.trackScreenViewed(.spineTextEditing)

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
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
        
        textField.becomeFirstResponder()
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
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
                self.textField.alpha = 1.0
            }
        })
    }
    
    func animateOff(completion: @escaping () -> Void) {
        let backgroundColor = view.backgroundColor
        
        textField.resignFirstResponder()
        textField.alpha = 0.0
        
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
        
        textField.inputAccessoryView = textToolBarView
        textField.text = product.spineText

        let initialContainerRatio = initialRect.width / initialRect.height
        
        spineFrameView.color = product.coverColor
        spineFrameView.spineTextRatio = product.photobookTemplate.spineTextRatio
        spineFrameView.coverHeight = product.photobookTemplate.coverSize.height
        spineFrameView.resetSpineColor()

        // Figure out the size of the spine frame
        view.layoutIfNeeded()
        let height = textField.bounds.width / product.photobookTemplate.spineTextRatio
        let width = height * initialContainerRatio
        
        spineFrameViewWidthConstraint.constant = width
        spineFrameViewHeightConstraint.constant = height
        
        textFieldHeightConstraint.constant = width // Since the cover will be on its side
        
        textViewBorderView.alpha = 0.0
        textField.alpha = 0.0
        
        setTextFieldAttributes()
        
        textToolBarView.select(fontType: fontType)
        
        backgroundColor = view.backgroundColor
        view.backgroundColor = .clear
        view.alpha = 1.0
        
        view.layoutIfNeeded()
        
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
    
    private func setTextFieldAttributes() {
        let fontSize = fontType.sizeForScreenToPageRatio(spineFrameViewHeightConstraint.constant / product.photobookTemplate.coverSize.height)
        let fontColor = product.coverColor.fontColor()
        textField.defaultTextAttributes = fontType.typingAttributes(fontSize: fontSize, fontColor: fontColor, isSpineText: true)
        textField.attributedText = fontType.attributedText(with: textField.text, fontSize: fontSize, fontColor: fontColor, isSpineText: true)
    }
    
    @IBAction func tappedCancelButton(_ sender: UIBarButtonItem) {
        delegate?.didCancelSpineTextEditing(self)
    }
    
    @IBAction func tappedDoneButton(_ sender: UIBarButtonItem) {
        dismissSpineTextEditing()
    }
    
    private func dismissSpineTextEditing() {
        // Check that the text still fits the bounds
        var attributedString: NSMutableAttributedString? = nil
        if textField.attributedText != nil {
            attributedString = NSMutableAttributedString(attributedString: textField.attributedText!)
            while !textFitsBounds(attributedString!) {
                attributedString!.deleteCharacters(in: NSMakeRange(attributedString!.length-1, 1))
            }
        }
        delegate?.didSaveSpineTextEditing(self, spineText: attributedString?.string.trimmingCharacters(in: .whitespaces), fontType: fontType)
    }
    
    private func textFitsBounds(_ attributedString: NSAttributedString) -> Bool {
        // Reduce the text area slightly to avoid the first character getting cut off
        return attributedString.size().width < textField.bounds.width - Constants.textFieldSafetyPadding
    }
}

extension SpineTextEditingViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // Allow deleting
        if string.count == 0 { return true }
        
        // Disallow pasting symbols
        if string.components(separatedBy: CharacterSet.symbols).joined().count < string.count { return false }

        // Check that the new length doesn't exceed the textField bounds
        let attributedString = NSMutableAttributedString(attributedString: textField.attributedText!)
        attributedString.replaceCharacters(in: range, with: string)

        return textFitsBounds(attributedString)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        dismissSpineTextEditing()
        return true
    }
}

extension SpineTextEditingViewController: TextToolBarViewDelegate {
    
    func didSelectFontType(_ fontType: FontType) {
        self.fontType = fontType
        setTextFieldAttributes()
    }
}
