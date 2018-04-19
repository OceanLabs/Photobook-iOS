//
//  CreditCardTableViewController.swift
//  Shopify
//
//  Created by Jaime Landazuri on 13/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

protocol CreditCardTableViewControllerDelegate: class {
    func didAddCreditCard(on viewController: CreditCardTableViewController)
}

class CreditCardTableViewController: UITableViewController {
    
    weak var delegate: CreditCardTableViewControllerDelegate?
    
    weak var cardNumberTextField: UITextField!
    weak var expiryDateTextField: UITextField!
    weak var cvvTextField: UITextField!
    
    private lazy var datePickerView: UIView = {
        var safeAreaHeight = CGFloat(0)
        if #available (iOS 11.0, *){
            safeAreaHeight = self.view.safeAreaInsets.bottom
        }
        
        let stackView = UIStackView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216 + safeAreaHeight)) //216 is the default UIPickerView height
        stackView.axis = .vertical
        let datePicker = UIPickerView()
        datePicker.dataSource = self
        datePicker.delegate = self
        stackView.addArrangedSubview(datePicker)
        if safeAreaHeight > 0{
            let safeAreaView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: safeAreaHeight))
            safeAreaView.backgroundColor = datePicker.backgroundColor
            stackView.addArrangedSubview(safeAreaView)
        }
        
        return stackView
    }()
    
    private var nextOrDoneButton: UIBarButtonItem = {
        let title = NSLocalizedString("Next", comment: "Next button on popup selection menus")
        return UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(nextTextField))
    }()
    
    private var selectedExpiryMonth: Int?
    private var selectedExpiryYear: Int?
    
    private lazy var accessoryView: UIToolbar = {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.bounds.width, height: 44.0))
        toolbar.isTranslucent = true
        toolbar.tintColor = .black
        
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.items = [ flexibleSpace, self.nextOrDoneButton ]
        
        return toolbar
    }()
    
    private struct Constants {
        static let creditCardRow = 0
        static let expiryDateRow = 1
        static let cvvRow = 2
        static let leadingSeparatorInset: CGFloat = 16
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("CreditCardTitle", value: "Card Details", comment: "Title for the credit card screen")
    }
    
    @objc private func nextTextField() {
        if cardNumberTextField.isFirstResponder {
            expiryDateTextField.becomeFirstResponder()
        } else if expiryDateTextField.isFirstResponder {
            cvvTextField.becomeFirstResponder()
        } else {
            saveCardDetails()
        }
    }
    
    override func viewDidLayoutSubviews() {
        var maxTextFieldX: CGFloat = 0
        
        for cell in tableView.visibleCells{
            if let cell = cell as? UserInputTableViewCell, cell.textField.frame.origin.x > maxTextFieldX{
                maxTextFieldX = cell.textField.frame.origin.x
            }
        }
        
        for cell in tableView.visibleCells{
            if let cell = cell as? UserInputTableViewCell{
                cell.textFieldLeadingConstraint.constant = maxTextFieldX
            }
        }
        
        super.viewDidLayoutSubviews()
    }

    @IBAction private func tappedSaveButton(_ sender: UIBarButtonItem) {
        saveCardDetails()
    }

    private func saveCardDetails() {
        view.endEditing(false)
        
        var creditCardIsValid = false
        if cardNumberTextField.text?.isEmpty ?? true || cardNumberTextField.text == FormConstants.requiredText {
            let cell = (tableView.cellForRow(at: IndexPath(row: Constants.creditCardRow, section: 0)) as! UserInputTableViewCell)
            cell.textField.text = FormConstants.requiredText
            cell.textField.textColor = FormConstants.errorColor
        }
        else if !cardNumberTextField.text!.isValidCardNumber() || cardNumberTextField.text!.cardType() == nil {
            tableView.beginUpdates()
            let cell = (tableView.cellForRow(at: IndexPath(row: Constants.creditCardRow, section: 0)) as! UserInputTableViewCell)
            cell.errorMessage = NSLocalizedString("CardNumberError", value: "This doesn't seem to be a valid card number", comment: "Error displayed when the card number field is missing or invalid")
            cell.textField.textColor = FormConstants.errorColor
            tableView.endUpdates()
        } else {
            creditCardIsValid = true
        }
        
        var cvvIsValid = false
        if cvvTextField.text?.isEmpty ?? true || cvvTextField.text == FormConstants.requiredText {
            let cell = (tableView.cellForRow(at: IndexPath(row: Constants.cvvRow, section: 0)) as! UserInputTableViewCell)
            cell.textField.text = FormConstants.requiredText
            cell.textField.textColor = FormConstants.errorColor
            cell.textField.isSecureTextEntry = false
        }
        else if (cvvTextField.text ?? "").count < 3 {
            if let cell = (tableView.cellForRow(at: IndexPath(row: Constants.cvvRow, section: 0)) as? UserInputTableViewCell){
                tableView.beginUpdates()
                cell.errorMessage = NSLocalizedString("CVVError", value: "The CVV is invalid. It should contain 3-4 digits.", comment: "Error displayed when the CVV field is empty or shorter than 3-4 digits")
                cell.textField.textColor = FormConstants.errorColor
                tableView.endUpdates()
            }
        } else {
            cvvIsValid = true
        }

        if selectedExpiryMonth == nil || selectedExpiryYear == nil {
            let cell = (tableView.cellForRow(at: IndexPath(row: Constants.expiryDateRow, section: 0)) as! UserInputTableViewCell)
            cell.textField.text = FormConstants.requiredText
            cell.textField.textColor = FormConstants.errorColor
        }
        
        guard let selectedExpiryYear = selectedExpiryYear, let selectedExpiryMonth = selectedExpiryMonth else { return }
        
        let components = Calendar.current.dateComponents([.month, .year], from: Date())
        let thisMonth = components.month!
        let thisYear = components.year!
        
        if thisYear == selectedExpiryYear && thisMonth > selectedExpiryMonth {
            if let cell = (tableView.cellForRow(at: IndexPath(row: Constants.expiryDateRow, section: 0)) as? UserInputTableViewCell) {
                tableView.beginUpdates()
                cell.errorMessage = NSLocalizedString("ExpiryDateInThePastError", value: "The expiry date is in the past", comment: "Error displayed when the expiry date entered is in the past")
                cell.textField.textColor = FormConstants.errorColor
                tableView.endUpdates()
            }
            return
        }
        
        guard creditCardIsValid && cvvIsValid else { return }

        let card = Card(number: cardNumberTextField.text!, expireMonth: selectedExpiryMonth, expireYear: selectedExpiryYear, cvv2: cvvTextField.text!)
        Card.currentCard = card
        
        OrderManager.shared.basketOrder.paymentMethod = .creditCard
        
        delegate?.didAddCreditCard(on: self)
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        OperationQueue.main.addOperation({
            UIMenuController.shared.setMenuVisible(false, animated: false)
        })
        return super.canPerformAction(action, withSender: sender)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.row {
        case Constants.creditCardRow: cardNumberTextField.becomeFirstResponder()
        case Constants.expiryDateRow: expiryDateTextField.becomeFirstResponder()
        case Constants.cvvRow: cvvTextField.becomeFirstResponder()
        default: break
        }
    }
}

//MARK: Table View Delegate

extension CreditCardTableViewController{
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userInput", for: indexPath) as! UserInputTableViewCell
        
        switch indexPath.row{
        case Constants.creditCardRow:
            cardNumberTextField = cell.textField
            cell.label?.text = NSLocalizedString("CardNumber", value: "Card Number", comment: "")
            cell.message = nil
            cell.textField.returnKeyType = .next
            cell.textField.placeholder = "Required"
            cell.textField.isSecureTextEntry = false
            cell.textField.textContentType = .creditCardNumber
            cell.topSeparator.isHidden = false
            cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
        case Constants.expiryDateRow:
            expiryDateTextField = cell.textField
            cell.label?.text = NSLocalizedString("ExpiryDate", value: "Expiry Date", comment: "")
            cell.textField.inputView = datePickerView
            cell.message = nil
            cell.textField.isSecureTextEntry = false
            cell.textField.placeholder = "Required"
            cell.topSeparator.isHidden = true
            cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
        case Constants.cvvRow:
            cvvTextField = cell.textField
            cell.label?.text = NSLocalizedString("CVV", comment: "Credit card security number")
            cell.message = nil
            cell.textField.returnKeyType = .done
            cell.textField.placeholder = "Required"
            cell.topSeparator.isHidden = true
            cell.separatorLeadingConstraint.constant = 0
            cell.textField.keyboardType = .numberPad
        default:
            break
        }
                
        cell.textField.inputAccessoryView = accessoryView
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("CardDetails/Header", value: "Details", comment: "Credit Card entry screen header")
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
}

extension CreditCardTableViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        // 12 months + blank, 20 years + blank
        return component == 0 ? 13 : 21
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if row == 0 { return "" }
        
        if component == 0 {
            return String(format: "%02d", row)
        } else {
            let year = Calendar.current.component(.year, from: Date())
            return String(year + row - 1)
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            selectedExpiryMonth = nil
            selectedExpiryYear = nil
            expiryDateTextField.text = ""
            return
        }
        
        let monthRow = pickerView.selectedRow(inComponent: 0)
        let yearRow = pickerView.selectedRow(inComponent: 1)
        guard monthRow > 0 && yearRow > 0 else {
            expiryDateTextField.text = ""
            return
        }
        
        selectedExpiryMonth = monthRow
        selectedExpiryYear = Calendar.current.component(.year, from: Date()) + yearRow - 1
        
        expiryDateTextField.text = String(format: "%02d / %d", selectedExpiryMonth!, selectedExpiryYear!)
    }
}

extension CreditCardTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == cardNumberTextField {
            let cell = (tableView.cellForRow(at: IndexPath(row: Constants.creditCardRow, section: 0)) as! UserInputTableViewCell)
            tableView.beginUpdates()
            cell.message = nil
            cell.textField.textColor = .black
            tableView.endUpdates()
        }
        else if textField == expiryDateTextField {
            let cell = (tableView.cellForRow(at: IndexPath(row: Constants.expiryDateRow, section: 0)) as! UserInputTableViewCell)
            tableView.beginUpdates()
            cell.message = nil
            cell.textField.textColor = .black
            tableView.endUpdates()
        }
        else if textField == cvvTextField {
            nextOrDoneButton.title = NSLocalizedString("Done", comment: "Done button on popup selection menus")
            let cell = (tableView.cellForRow(at: IndexPath(row: Constants.cvvRow, section: 0)) as! UserInputTableViewCell)
            cell.message = nil
            cell.textField.textColor = .black
            cell.textField.isSecureTextEntry = true
        }
        
        
        if textField.text == FormConstants.requiredText {
            textField.text = nil
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if textField == cvvTextField {
            nextOrDoneButton.title = NSLocalizedString("Next", comment: "Next button on popup selection menus")
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == cardNumberTextField {
            let selStartPos = textField.selectedTextRange!.start
            let idx = textField.offset(from: textField.beginningOfDocument, to: selStartPos)
            
            var offset = -1
            var aRange = range
            
            if (textField.text! as NSString).substring(with: range) == " " && string.isEmpty {
                aRange = NSRange.init(location: range.location - 1, length: range.length)
                offset = -2
            }
            
            let aText = (textField.text! as NSString).replacingCharacters(in: aRange, with: string)
            textField.text = aText.creditCardFormatted()
            
            if string.isEmpty && idx + offset > (textField.text?.count ?? 0) {
                offset = -2
            } else if !string.isEmpty {
                offset = 1
                if (textField.text?.count ?? 0) > idx {
                    let startIndex = textField.text!.index(textField.text!.startIndex, offsetBy: idx)
                    let endIndex = textField.text!.index(startIndex, offsetBy: 1)
                    let aString = textField.text![startIndex..<endIndex]
                    if aString == " " {
                        offset = 2
                    }
                } else {
                    offset = 0
                }
            }
            
            let cursorPosition = textField.position(from: textField.beginningOfDocument, offset: idx + offset)!
            let selectedRange = textField.textRange(from: cursorPosition, to: cursorPosition)
            textField.selectedTextRange = selectedRange
            
            return false
        } else if textField == cvvTextField {
            guard let text = textField.text else { return true }
            if string.components(separatedBy: CharacterSet.decimalDigits.inverted).count > 1 { return false }
            else if text.count >= 4 && string != "" {
                textField.text = String(text[..<text.index(text.startIndex, offsetBy: 4)])
                return false
            }
            return true
        } else if textField == expiryDateTextField {
            return false
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        nextTextField()
        return false
    }
}
