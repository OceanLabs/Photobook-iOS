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

/// Protocol a delegate should conform to to react to the selection of a value
protocol AmountPickerDelegate : class {
    func amountPickerDidSelectValue(_ value: Int)
}

class AmountPickerViewController: UIViewController {
    
    @IBOutlet private weak var optionTitleLabel: UILabel! { didSet { optionTitleLabel.scaleFont() } }
    @IBOutlet private weak var optionPickerView: UIPickerView!
    @IBOutlet private weak var contentViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet private weak var contentViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var doneButton: UIButton! { didSet { doneButton.titleLabel?.scaleFont() } }
    
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
