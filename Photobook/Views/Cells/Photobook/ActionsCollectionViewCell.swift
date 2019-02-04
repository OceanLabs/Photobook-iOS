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

struct ActionButtonViewConfiguration {
    var title: String?
    var image: UIImage?
}

protocol ActionsCollectionViewCellDelegate: class {
    func actionButtonConfigurationForButton(at index: Int, indexPath: IndexPath) -> ActionButtonViewConfiguration?
    func didCloseCell(at indexPath: IndexPath)
    func didOpenCell(at indexPath: IndexPath)
    func didTapActionButton(at index: Int, for indexPath: IndexPath)
}

class ActionsCollectionViewCell: UICollectionViewCell {
    
    private struct Constants {
        static let actionButtonsLeftMargin: CGFloat = 20.0
        static let preferredActionTriggerOffset: CGFloat = 40.0
        static let swipeDetectionVelocity: CGFloat = 20.0
        static let actionsViewBackgroundColor = UIColor(red: 0.86, green: 0.86, blue: 0.86, alpha: 1.0)
    }
    
    // Superview for the cell content. Different from UICollectionViewCell's contentView.
    @IBOutlet private var cellContentView: UIView!
    // Superview where the action buttons are added
    @IBOutlet private var actionsView: UIView!
    
    @IBOutlet private var actionButtons: [ActionButtonView]! {
        didSet {
            activeButtons = actionButtons.count
            actionButtonIsInPlace = [Bool](repeating: false, count: actionButtons.count)
        }
    }
    @IBOutlet private var actionButtonTrailingConstraints: [NSLayoutConstraint]! {
        didSet {
            actionButtonsStartingTrailingConstraintsConstants = actionButtonTrailingConstraints.map { $0.constant }
        }
    }
    @IBOutlet private var cellContentViewTrailingConstraint: NSLayoutConstraint!
    private var removableTrailingConstraints: [NSLayoutConstraint]!
    private var actionButtonsStartingTrailingConstraintsConstants: [CGFloat]!
    
    private var actionButtonIsInPlace: [Bool]!
    private var activeButtons = 0
    private var startingRightEdgeContentPosition: CGFloat!
    private var showingPreferredAction = false
    
    private var actionsViewWidth: CGFloat {
        var width = actionButtonsStartingTrailingConstraintsConstants.first! * 2.0 // left and right paddings
        for i in 0 ..< activeButtons {
            width += actionButtons[i].bounds.width
        }
        return width
    }
    
    private func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let constant: CGFloat = 0.5
        let result = (constant * abs(offset) * dimension) / (dimension + constant * abs(offset))
        return offset < 0.0 ? -result : result
    }
    
    var indexPath: IndexPath!
    var shouldRevealActions = true
    var canUsePreferredAction = false
    var isOpen: Bool { return cellContentViewTrailingConstraint.constant > 0.0 }
    weak var actionsDelegate: ActionsCollectionViewCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setUpActions()
    }
    
    private var hasDoneSetup = false
    func setUpActions() {
        setupActionButtons()
        
        if !hasDoneSetup {
            hasDoneSetup = true
            setupGestures()
        }

        animateCellClosed(duration: 0.0)
    }
    
    private func setupActionButtons() {
        var trailingConstraints = [NSLayoutConstraint]()
        
        let action = { (actionButton: ActionButtonView) in
            self.tappedActionButton(actionButton)
        }
        
        activeButtons = actionButtons.count
        for (index, actionButton) in actionButtons.enumerated() {
            guard let buttonConfiguration = actionsDelegate?.actionButtonConfigurationForButton(at: index, indexPath: indexPath) else {
                activeButtons -= 1
                actionButton.isHidden = true
                continue
            }
            
            actionButton.isHidden = false
            
            if index > 0 {
                trailingConstraints.append(actionButtonTrailingConstraints[index])
            }
            
            actionButton.title = buttonConfiguration.title
            actionButton.image = buttonConfiguration.image
            actionButton.action = action
        }

        removableTrailingConstraints = trailingConstraints
    }
    
    private func setupGestures() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panActionsCollectionViewCell(_:)))
        panGestureRecognizer.delegate = self
        cellContentView.addGestureRecognizer(panGestureRecognizer)
    }
    
    private func isActionButtonAvailable(_ actionButton: ActionButtonView) -> Bool {
        return actionButtons.firstIndex(of: actionButton)! < activeButtons
    }
    
    private var panStartPoint: CGPoint!
    private var currentPoint: CGPoint!
    private var previousPoint: CGPoint!
    private var velocity: CGFloat!
    private var didSwipe = false
    private var isPanning = false
    
    @IBAction private func panActionsCollectionViewCell(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard shouldRevealActions else { return }
        
        switch gestureRecognizer.state {
        case .began:
            actionsView.alpha = 1.0
            
            panStartPoint = gestureRecognizer.translation(in: cellContentView)
            previousPoint = panStartPoint
            
            startingRightEdgeContentPosition = cellContentViewTrailingConstraint.constant
        case .changed:
            currentPoint = gestureRecognizer.translation(in: cellContentView)
            
            velocity = previousPoint.x - currentPoint.x
            
            isPanning = abs(previousPoint.x - currentPoint.x) >= abs(previousPoint.y - currentPoint.y)
            guard isPanning else {
                previousPoint = .zero
                currentPoint = .zero
                return
            }

            let delta = currentPoint.x - panStartPoint.x
            let isPanningLeft = currentPoint.x < previousPoint.x
            
            didSwipe = !didSwipe && isPanningLeft && abs(velocity) > Constants.swipeDetectionVelocity

            var constant: CGFloat!
            var shouldShowPreferredAction = false
            var shouldHidePreferredAction = false
            let hasMoreThanOneButton = activeButtons > 1
            
            if startingRightEdgeContentPosition == 0 {
                if isPanningLeft {
                    if -delta > actionsViewWidth {
                        constant = actionsViewWidth + rubberBandDistance(offset: -delta - actionsViewWidth, dimension: bounds.width)
                        shouldShowPreferredAction = canUsePreferredAction && hasMoreThanOneButton && !showingPreferredAction && (-delta - actionsViewWidth) > Constants.preferredActionTriggerOffset
                    } else {
                        constant = min(-delta, actionsViewWidth)
                        constant = max(constant, 0.0)
                    }
                } else {
                    if -delta < actionsViewWidth {
                        constant = max(-delta, 0.0)
                    } else {
                        constant = actionsViewWidth + rubberBandDistance(offset: -delta - actionsViewWidth, dimension: bounds.width)
                    }
                    shouldHidePreferredAction = hasMoreThanOneButton && showingPreferredAction && constant < actionsViewWidth + Constants.preferredActionTriggerOffset
                }
            } else {
                if -delta > 0.0 {
                    constant = actionsViewWidth + rubberBandDistance(offset: -delta, dimension: bounds.width)
                } else {
                    constant = max(startingRightEdgeContentPosition - delta, 0.0)
                }

                if isPanningLeft {
                    shouldShowPreferredAction = canUsePreferredAction && hasMoreThanOneButton && !showingPreferredAction && -delta > Constants.preferredActionTriggerOffset
                } else {
                    shouldHidePreferredAction = hasMoreThanOneButton && showingPreferredAction && constant < actionsViewWidth + Constants.preferredActionTriggerOffset
                }
            }
            
            cellContentViewTrailingConstraint.constant = constant
            layoutIfNeeded()
            
            previousPoint = currentPoint
            
            updateActionViewBackgroundColor(to: constant / actionsViewWidth)
            
            if shouldShowPreferredAction {
                let generator = UISelectionFeedbackGenerator()
                generator.selectionChanged()
                
                animatePreferredAction(duration: 0.2)
            } else if shouldHidePreferredAction {
                animatePreferredAction(duration: 0.2)
            } else {
                if showingPreferredAction {
                    actionButtonTrailingConstraints.first!.constant = constant - actionButtons.first!.bounds.width - Constants.actionButtonsLeftMargin
                } else {
                    for (index, actionButton) in actionButtons.enumerated() {
                        guard isActionButtonAvailable(actionButton) else { break }
                        
                        let inPlace = constant > maxXCoordinateForActionButton(actionButton)
                        if inPlace != actionButtonIsInPlace[index] {
                            actionButtonIsInPlace[index] = inPlace
                            setInPlace(inPlace, actionButton: actionButton)
                        }
                    }
                    
                    UIView.animate(withDuration: 0.1, delay: 0.0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
                        self.layoutIfNeeded()
                    }, completion: nil)
                }
            }
            
        case .ended, .cancelled:
            isPanning = false

            // Check if there was a swipe
            if gestureRecognizer.state == .ended && didSwipe {
                animateCell(open: velocity > 0, duration: 0.1) { self.didSwipe = false }
                return
            }
            
            let open = cellContentViewTrailingConstraint.constant > actionsViewWidth * 0.5 && !showingPreferredAction
            let duration = showingPreferredAction ? 0.3 : 0.1
            
            animateCell(open: open, duration: duration) { self.didSwipe = false }
        default:
            break
        }
    }
    
    private func animateCell(open: Bool, duration: Double, completion: (()->())? = nil) {
        actionButtons.forEach {
            guard isActionButtonAvailable($0) else { return }
            setInPlace(open, actionButton: $0)
        }
        
        let animateTo = open ? actionsViewWidth : 0.0
        cellContentViewTrailingConstraint.constant = animateTo
        
        if showingPreferredAction {
            actionButtonTrailingConstraints.first!.constant = actionButtonsStartingTrailingConstraintsConstants.first!
        }
        
        UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            self.updateActionViewBackgroundColor(to: animateTo > 0.0 ? 1.0 : 0.0)
            self.layoutIfNeeded()
        }) { _ in
            if !open {
                self.actionsView.alpha = 0.0
                self.actionsDelegate?.didCloseCell(at: self.indexPath)
            } else {
                self.actionsDelegate?.didOpenCell(at: self.indexPath)
            }
            
            if self.showingPreferredAction {
                self.animatePreferredAction(duration: 0.0)
                self.showingPreferredAction = false
                
                // Trigger preferred action
                self.tappedActionButton(self.actionButtons.first!)
                self.actionsDelegate?.didCloseCell(at: self.indexPath)
            }
            
            completion?()
        }
    }
    
    func animateCellClosed(duration: Double = 0.2, delay: Double = 0.0, completion: (()->())? = nil) {
        cellContentViewTrailingConstraint.constant = 0.0
        
        actionButtons.forEach {
            guard isActionButtonAvailable($0) else { return }
            setInPlace(false, actionButton: $0)
        }
        
        UIView.animate(withDuration: duration, delay: delay, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            self.updateActionViewBackgroundColor(to: 0.0)
            self.layoutIfNeeded()
        }) { _ in
            self.actionsView.alpha = 0.0
            completion?()
        }
    }
    
    private func allButtonsAreInPlace() -> Bool {
        return actionButtonIsInPlace.contains(false)
    }
    
    private func animatePreferredAction(duration: Double) {
        let alpha: CGFloat!
        if showingPreferredAction {
            actionButtonTrailingConstraints.first!.constant = actionButtonsStartingTrailingConstraintsConstants.first!
            actionsView.addConstraints(removableTrailingConstraints)
            showingPreferredAction = false
            alpha = 1.0
        } else {
            actionButtonTrailingConstraints.first!.constant = cellContentViewTrailingConstraint.constant - actionButtons.first!.bounds.width - Constants.actionButtonsLeftMargin
            actionsView.removeConstraints(removableTrailingConstraints)
            showingPreferredAction = true
            alpha = 0.0
        }

        UIView.animate(withDuration: duration, delay: 0.0, options: .beginFromCurrentState, animations: {
            for index in 1 ..< self.actionButtons.count {
                self.actionButtons[index].alpha = alpha
            }
            self.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func updateActionViewBackgroundColor(to alpha: CGFloat) {
        actionsView.backgroundColor = Constants.actionsViewBackgroundColor.withAlphaComponent(alpha)
    }
    
    private func maxXCoordinateForActionButton(_ actionButton: ActionButtonView) -> CGFloat {
        let index = actionButtons.firstIndex(of: actionButton)!
        var coordinate = actionsView.frame.width - actionButton.frame.midX
        if !actionButtonIsInPlace[index] {
            coordinate -= Constants.actionButtonsLeftMargin
        }
        return coordinate
    }
    
    private func setInPlace(_ inPlace: Bool, actionButton: ActionButtonView) {
        let index = actionButtons.firstIndex(of: actionButton)!
        var constant = actionButtonsStartingTrailingConstraintsConstants[index]
        if !inPlace {
            constant += Constants.actionButtonsLeftMargin
        }
        actionButtonTrailingConstraints[index].constant = constant
    }
    
    private func tappedActionButton(_ actionButton: ActionButtonView) {
        let index = self.actionButtons.firstIndex(of: actionButton)!
        actionsDelegate?.didTapActionButton(at: index, for: self.indexPath)
    }
 }

extension ActionsCollectionViewCell: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !isPanning
    }
}
