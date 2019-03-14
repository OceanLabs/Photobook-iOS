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

struct FormConstants {
    static let errorColor = UIColor(red:1, green:0.23, blue:0.19, alpha:1)
    static let requiredText = NSLocalizedString("UserInputRequired", value: "Required", comment: "User input required")
    static let minPhoneNumberLength = 5
}

protocol AddressTableViewControllerDelegate: class {
    func addressTableViewControllerDidEdit()
}

class AddressTableViewController: UITableViewController {
    
    lazy var deliveryDetails = OLDeliveryDetails()
    var index: Int?
    
    weak var delegate: AddressTableViewControllerDelegate?
    
    private weak var firstNameTextField: UITextField!
    private weak var lastNameTextField: UITextField!
    private weak var emailTextField: UITextField!
    private weak var phoneTextField: UITextField!
    private weak var line1TextField: UITextField!
    private weak var line2TextField: UITextField!
    private weak var cityTextField: UITextField!
    private weak var stateOrCountyTextField: UITextField!
    private weak var zipOrPostcodeTextField: UITextField!
    
    private struct DetailsFieldLabels {
        static let name = NSLocalizedString("DeliveryDetails/Name", value: "Name", comment: "Delivery Details screen first name textfield title")
        static let lastName = NSLocalizedString("DeliveryDetails/LastName", value: "Last Name", comment: "Delivery Details screen last name textfield title")
        static let email = NSLocalizedString("DeliveryDetails/Email", value: "Email", comment: "Delivery Details screen Email textfield title")
        static let phone = NSLocalizedString("DeliveryDetails/Phone", value: "Phone", comment: "Delivery Details screen Phone textfield title")
        
        static let line1 = NSLocalizedString("AddressEntry/Line1", value: "Line1", comment: "Address Entry screen line1 textfield title")
        static let line2 = NSLocalizedString("AddressEntry/Line2", value: "Line2", comment: "Address Entry screen line2 textfield title")
        static let city = NSLocalizedString("AddressEntry/City", value: "City", comment: "Address Entry screen City textfield title")
        static let state = NSLocalizedString("AddressEntry/State", value: "State", comment: "State of the recipient address (U.S. addresses only)")
        static let county = NSLocalizedString("AddressEntry/County", value: "County", comment: "Address Entry screen County textfield title")
        static let zip = NSLocalizedString("AddressEntry/ZipCode", value: "Zip Code", comment: "Zip code of the recipient address (U.S. addresses only)")
        static let postcode = NSLocalizedString("AddressEntry/Postcode", value: "Postcode", comment: "Address Entry screen Postcode textfield title")
        static let country = NSLocalizedString("AddressEntry/Country", value: "Country", comment: "Address Entry screen Country textfield title")
    }

    private enum Row: Int {
        case name, lastName, email, phone, line1, line2, city, stateOrCounty, zipOrPostcode, country
    }

    private struct Constants {
        static let leadingSeparatorInset: CGFloat = 16
        static let phoneExplanation = NSLocalizedString("DeliveryDetails/PhoneExplanation", value: "Required by the postal service in case there are any issues with the delivery", comment: "Explanation of why the phone number is needed")
    }

    private lazy var phoneToolbar: UIToolbar = {
        let nextTitle = NSLocalizedString("DeliveryDetailsEdit/Next", value: "Next", comment: "Button title to move the focus to the next field")
        let nextBarButtonItem = UIBarButtonItem(title: nextTitle, style: .plain, target: self, action: #selector(moveToNextFieldAfterPhone(_:)))
        let toolbar = UIToolbar()
        toolbar.barStyle = .default
        toolbar.backgroundColor = .white
        toolbar.items = [ UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), nextBarButtonItem]
        toolbar.sizeToFit()
        return toolbar
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("DeliveryDetailsEdit/Title", value: "Delivery Details", comment: "Delivery details entry screen title")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        if identifier == "countryPickerSegue", let countryPicker = segue.destination as? CountryPickerTableViewController {
            countryPicker.delegate = self
            countryPicker.selectedCountry = sender as? Country
        }
        
    }
    
    @IBAction private func saveTapped(_ sender: Any) {
        view.endEditing(false)
        
        tableView.beginUpdates()
        let firstNameInvalidReason = check(firstNameTextField)
        let lastNameInvalidReason = check(lastNameTextField)
        let emailInvalidReason = check(emailTextField)
        let phoneInvalidReason = check(phoneTextField)
        let line1IsValid = check(line1TextField)
        let cityIsValid = check(cityTextField)
        let postCodeIsValid = check(zipOrPostcodeTextField)
        let stateOrCountyIsValid = check(stateOrCountyTextField)
        tableView.endUpdates()
        
        if firstNameInvalidReason == nil && lastNameInvalidReason == nil && emailInvalidReason == nil && phoneInvalidReason == nil && line1IsValid == nil && cityIsValid == nil && postCodeIsValid == nil && stateOrCountyIsValid == nil {
            
            if let index = index {
                OLDeliveryDetails.edit(deliveryDetails, at: index)
            } else {
                OLDeliveryDetails.add(deliveryDetails)
            }
            
            OrderManager.shared.basketOrder.deliveryDetails = deliveryDetails
            delegate?.addressTableViewControllerDidEdit()
        } else {
            var errorMessage = ""
            if firstNameInvalidReason == FormConstants.requiredText {
                errorMessage += DetailsFieldLabels.name + ", "
            }
            if lastNameInvalidReason == FormConstants.requiredText {
                errorMessage += DetailsFieldLabels.lastName + ", "
            }
            if emailInvalidReason == FormConstants.requiredText {
                errorMessage += DetailsFieldLabels.email + ", "
            }
            if phoneInvalidReason == FormConstants.requiredText {
                errorMessage += DetailsFieldLabels.phone + ", "
            }
            if line1IsValid == FormConstants.requiredText {
                errorMessage += DetailsFieldLabels.line1 + ", "
            }
            if cityIsValid == FormConstants.requiredText {
                errorMessage += DetailsFieldLabels.city + ", "
            }
            if postCodeIsValid == FormConstants.requiredText {
                errorMessage += DetailsFieldLabels.postcode + ", "
            }
            if stateOrCountyIsValid == FormConstants.requiredText {
                errorMessage += DetailsFieldLabels.county + ", "
            }
            
            if !errorMessage.isEmpty {
                errorMessage = NSLocalizedString("Accessibility/AddressRequiredInformationMissing", value: "Required information missing: ", comment: "Accessibility message informing the user that some of the required information is missing") + errorMessage.trimmingCharacters(in: CharacterSet(charactersIn: ", ")) + ". "
            }
            
            let phoneIsInvalid = phoneInvalidReason != nil && phoneInvalidReason != FormConstants.requiredText
            let emailIsInvalid = emailInvalidReason != nil && emailInvalidReason != FormConstants.requiredText
            
            if  phoneIsInvalid || emailIsInvalid {
                errorMessage += NSLocalizedString("Accessibility/InvalidInformation", value: "Some of the entered information is invalid.", comment: "Accessibility message letting the user know that some of the information they entered is invalid")
                if emailIsInvalid {
                    errorMessage += emailInvalidReason!
                }
                if phoneIsInvalid {
                    errorMessage += phoneInvalidReason!
                }
            }

            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: errorMessage.trimmingCharacters(in: CharacterSet(charactersIn: ", ")))
        }
    }
    
    private func check(_ textField: UITextField) -> String? {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let text = textField.text, !text.isEmpty, text != FormConstants.requiredText else {
            textField.text = FormConstants.requiredText
            textField.textColor = FormConstants.errorColor
            return FormConstants.requiredText
        }
        
        if textField == emailTextField {
            let cell = (tableView.cellForRow(at: IndexPath(row: Row.email.rawValue, section: 0)) as? UserInputTableViewCell)
            if let text = cell?.textField.text,
                !text.isValidEmailAddress() {
                let invalidReason = NSLocalizedString("DeliveryDetails/Email is invalid", value: "Email is invalid", comment: "Error message saying that the email address is invalid")
                cell?.errorMessage = invalidReason
                cell?.textField.textColor = FormConstants.errorColor
                return invalidReason
            }
        } else if textField == phoneTextField {
            let cell = (tableView.cellForRow(at: IndexPath(row: Row.phone.rawValue, section: 0)) as? UserInputTableViewCell)
            if let text = cell?.textField.text,
                text.count < FormConstants.minPhoneNumberLength || text == FormConstants.requiredText {
                let invalidReason = NSLocalizedString("DeliveryDetails/Phone is invalid", value: "Phone is invalid", comment: "Error message saying that the phone number is invalid")
                cell?.errorMessage = invalidReason
                cell?.textField.textColor = FormConstants.errorColor
                return invalidReason
            }
        }
        
        return nil
    }
    
    private func textField(after textField: UITextField) -> UITextField? {
        if textField === firstNameTextField {
            return lastNameTextField
        } else if textField === lastNameTextField {
            return emailTextField
        } else if textField === emailTextField {
            return phoneTextField
        } else if textField == phoneTextField {
            return line1TextField
        } else if textField === line1TextField {
            return line2TextField
        } else if textField === line2TextField {
            return cityTextField
        } else if textField === cityTextField {
            return stateOrCountyTextField
        } else if textField === stateOrCountyTextField {
            return zipOrPostcodeTextField
        }
        
        return nil
    }
    
    private func configure(cell: UserInputTableViewCell, for row: Row) {
        
        cell.textField.keyboardType = .default
        cell.textField.isUserInteractionEnabled = true
        cell.textField.placeholder = nil
        cell.textField.autocapitalizationType = .words
        
        cell.topSeparator.isHidden = true
        cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
        cell.textField.placeholder = FormConstants.requiredText
        cell.message = nil
        
        switch row {
        case .name:
            cell.label?.text = DetailsFieldLabels.name
            cell.textField.textContentType = .givenName
            cell.textField.keyboardType = .default
            cell.textField.returnKeyType = .next
            cell.textField.autocapitalizationType = .words
            cell.textField.text = deliveryDetails.firstName
            cell.topSeparator.isHidden = false
            cell.textField.accessibilityLabel = cell.label?.text
            firstNameTextField = cell.textField
            firstNameTextField.accessibilityIdentifier = "firstNameTextField"
        case .lastName:
            cell.label?.text = DetailsFieldLabels.lastName
            cell.textField.textContentType = .familyName
            cell.textField.keyboardType = .default
            cell.textField.returnKeyType = .next
            cell.textField.autocapitalizationType = .words
            cell.textField.text = deliveryDetails.lastName
            cell.textField.accessibilityLabel = cell.label?.text
            lastNameTextField = cell.textField
            lastNameTextField.accessibilityIdentifier = "lastNameTextField"
        case .email:
            cell.label?.text = DetailsFieldLabels.email
            cell.textField.textContentType = .emailAddress
            cell.textField.keyboardType = .emailAddress
            cell.textField.returnKeyType = .next
            cell.textField.autocapitalizationType = .none
            cell.textField.text = deliveryDetails.email
            cell.accessibilityIdentifier = "emailCell"
            cell.textField.accessibilityLabel = cell.label?.text
            emailTextField = cell.textField
            emailTextField.accessibilityIdentifier = "emailTextField"
        case .phone:
            cell.label?.text = DetailsFieldLabels.phone
            cell.message = Constants.phoneExplanation
            cell.textField.textContentType = .telephoneNumber
            cell.textField.keyboardType = .phonePad
            cell.textField.returnKeyType = .next
            cell.textField.text = deliveryDetails.phone
            cell.textField.inputAccessoryView = phoneToolbar
            cell.accessibilityIdentifier = "phoneCell"
            cell.textField.accessibilityLabel = cell.label?.text
            cell.textField.accessibilityHint = Constants.phoneExplanation
            phoneTextField = cell.textField
            phoneTextField.accessibilityIdentifier = "phoneTextField"
        case .line1:
            cell.label?.text = DetailsFieldLabels.line1
            cell.textField.textContentType = .streetAddressLine1
            cell.textField.returnKeyType = .next
            cell.textField.text = deliveryDetails.line1
            line1TextField = cell.textField
            line1TextField.accessibilityIdentifier = "line1TextField"
            line1TextField.accessibilityLabel = cell.label?.text
        case .line2:
            cell.label?.text = DetailsFieldLabels.line2
            cell.textField.textContentType = .streetAddressLine1
            cell.textField.returnKeyType = .next
            cell.textField.text = deliveryDetails.line2
            cell.textField.placeholder = nil
            line2TextField = cell.textField
            line2TextField.accessibilityIdentifier = "line2TextField"
            line2TextField.accessibilityLabel = cell.label?.text
        case .city:
            cell.label?.text = DetailsFieldLabels.city
            cell.textField.textContentType = .addressCity
            cell.textField.returnKeyType = .next
            cell.textField.text = deliveryDetails.city
            cityTextField = cell.textField
            cityTextField.accessibilityIdentifier = "cityTextField"
            cityTextField.accessibilityLabel = cell.label?.text
        case .stateOrCounty:
            if deliveryDetails.country.codeAlpha3 == "USA" {
                cell.label?.text = DetailsFieldLabels.state
            } else {
                cell.label?.text = DetailsFieldLabels.county
            }
            cell.textField.textContentType = .addressState
            cell.textField.returnKeyType = .next
            cell.textField.text = deliveryDetails.stateOrCounty
            stateOrCountyTextField = cell.textField
            stateOrCountyTextField.accessibilityIdentifier = "stateOrCountyTextField"
            stateOrCountyTextField.accessibilityLabel = cell.label?.text
        case .zipOrPostcode:
            if deliveryDetails.country.codeAlpha3 == "USA" {
                cell.label?.text = DetailsFieldLabels.zip
            } else {
                cell.label?.text = DetailsFieldLabels.postcode
            }
            cell.textField.textContentType = .postalCode
            cell.textField.returnKeyType = .done
            cell.textField.autocapitalizationType = .allCharacters
            cell.textField.text = deliveryDetails.zipOrPostcode
            zipOrPostcodeTextField = cell.textField
            zipOrPostcodeTextField.accessibilityIdentifier = "zipOrPostcodeTextField"
            zipOrPostcodeTextField.accessibilityLabel = cell.label?.text
        case .country:
            cell.label?.text = DetailsFieldLabels.country
            cell.textField.isUserInteractionEnabled = false
            cell.textField.text = deliveryDetails.country.name
            cell.textField.accessibilityIdentifier = "countryTextField"
            cell.textField.accessibilityLabel = cell.label?.text
            cell.textField.accessibilityTraits = UIAccessibilityTraits.staticText
            cell.textField.accessibilityHint = NSLocalizedString("Accessibility/DoubleTapToChangeHint", value: "Double tap to change", comment: "Accessibility hint letting the user know that they can double tap to change the selected value")
            cell.separatorLeadingConstraint.constant = 0
        }
    }
}

extension AddressTableViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("DeliveryDetailsEntry/DetailsHeader", value: "Details", comment: "Delivery Details Entry section header")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = Row(rawValue: indexPath.row) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "userInput", for: indexPath) as! UserInputTableViewCell
        configure(cell: cell, for: row)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? UserInputTableViewCell else { return }
        
        if cell.textField.isUserInteractionEnabled{
            cell.textField.becomeFirstResponder()
        }
        else {
            performSegue(withIdentifier: "countryPickerSegue", sender: deliveryDetails.country)
        }
    }
}

extension AddressTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == FormConstants.requiredText {
            textField.text = nil
        }
        
        tableView.beginUpdates()
        switch textField {
        case phoneTextField:
            let cell = (tableView.cellForRow(at: IndexPath(row: Row.phone.rawValue, section: 0)) as! UserInputTableViewCell)
            cell.message = Constants.phoneExplanation
        case emailTextField:
            let cell = (tableView.cellForRow(at: IndexPath(row: Row.email.rawValue, section: 0)) as! UserInputTableViewCell)
            cell.message = nil
        default:
            break
        }
        tableView.endUpdates()
        
        textField.textColor = .black
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        tableView.beginUpdates()
        switch textField {
        case firstNameTextField:
            _ = check(textField)
            deliveryDetails.firstName = textField.text
        case lastNameTextField:
            _ = check(textField)
            deliveryDetails.lastName = textField.text
        case emailTextField:
            _ = check(emailTextField)
            deliveryDetails.email = textField.text
        case phoneTextField:
            _ = check(phoneTextField)
            deliveryDetails.phone = textField.text
        case line1TextField:
            _ = check(textField)
            deliveryDetails.line1 = line1TextField.text
        case line2TextField:
            deliveryDetails.line2 = line2TextField.text
        case cityTextField:
            _ = check(textField)
            deliveryDetails.city = cityTextField.text
        case stateOrCountyTextField:
            deliveryDetails.stateOrCounty = stateOrCountyTextField.text
        case zipOrPostcodeTextField:
            _ = check(textField)
            deliveryDetails.zipOrPostcode = zipOrPostcodeTextField.text
        default:
            break
        }
        tableView.endUpdates()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let nextTextField = self.textField(after: textField) {
            nextTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        
        return false
    }
    
    @IBAction func moveToNextFieldAfterPhone(_ sender: UIBarButtonItem) {
        guard let nextTextField = self.textField(after: phoneTextField) else { return }
        nextTextField.becomeFirstResponder()
    }
}

extension AddressTableViewController: CountryPickerTableViewControllerDelegate {
    
    func countryPickerDidPick(country: Country) {
        deliveryDetails.country = country
        tableView.reloadData()
    }
    
}

