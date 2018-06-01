//
//  OptionsViewController.swift
//  Shopify
//
//  Created by Jaime Landazuri on 04/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

/// Protocol a delegate should conform to to react to the selection of a value
protocol AmountPickerDelegate : class {
    func amountPickerDidSelectValue(_ value: Int)
}

class AmountPickerViewController: UIViewController {
    
    @IBOutlet private weak var optionTitleLabel: UILabel! {
        didSet {
            if #available(iOS 11.0, *) {
                optionTitleLabel.font = UIFontMetrics.default.scaledFont(for: optionTitleLabel.font)
                optionTitleLabel.adjustsFontForContentSizeCategory = true
            }
        }
    }
    @IBOutlet private weak var optionPickerView: UIPickerView!
    @IBOutlet private weak var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var doneButton: UIButton! {
        didSet {
            if #available(iOS 11.0, *) {
                doneButton.titleLabel?.font = UIFontMetrics.default.scaledFont(for: doneButton.titleLabel!.font)
                doneButton.titleLabel?.adjustsFontForContentSizeCategory = true
            }
        }
    }
    
    /// The name to display as title. E.g. Size, colour
    var optionName: String?
    /// If the user has previously selected a value
    var selectedValue: Int?
    /// The minimum value of the range displayed
    var minimum:Int = 1
    /// The maximum value of the range displayed
    var maximum:Int = 25
    
    private var range:Int {
        get {
            let value = maximum - minimum + 1
            if value < 0 {
                print("AmountPickerViewController: Minimum value can't be higher than the maximum of the range")
                return 0
            }
            return value
        }
    }
    
    
    weak var delegate: AmountPickerDelegate?
    
    private var hasRunSetup = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        contentViewBottomConstraint.constant = -contentViewHeightConstraint.constant
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasRunSetup {
            setup()
            hasRunSetup = true
        }
    }
    
    private func setup() {
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.0)

        optionTitleLabel.text = optionName
        
        if let selectedValue = selectedValue, selectedValue >= minimum && selectedValue <= maximum  {
            let selectedIndex = selectedValue - 1
            optionPickerView.selectRow(selectedIndex, inComponent: 0, animated: false)
        }
        
        view.layoutIfNeeded()
        
        contentViewBottomConstraint.constant = 0.0
        UIView.animate(withDuration: 0.25, animations: {
            self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
            self.view.layoutIfNeeded()
        })
    }
    
    @IBAction func tappedCloseButton(_ sender: Any) {
        delegate?.amountPickerDidSelectValue(optionPickerView.selectedRow(inComponent: 0) + 1)

        contentViewBottomConstraint.constant = -contentViewHeightConstraint.constant
        
        UIView.animate(withDuration: 0.25, animations: {
            self.view.backgroundColor = UIColor(white: 0.0, alpha: 0.0)
            self.view.layoutIfNeeded()
        }, completion:{(finished: Bool) -> Void in
            self.dismiss(animated: false, completion: nil)
        })
    }
}

extension AmountPickerViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return range
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return "\(minimum + row)"
    }
}
