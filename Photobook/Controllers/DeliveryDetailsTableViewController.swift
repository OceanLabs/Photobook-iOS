//
//  DeliveryDetailsTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class DeliveryDetailsTableViewController: UITableViewController {
    
    lazy var details = DeliveryDetails()
    
    weak var firstNameTextField: UITextField!
    weak var lastNameTextField: UITextField!
    weak var emailTextField: UITextField!
    weak var phoneTextField: UITextField!

    private enum Section: Int {
        case details, deliveryAddress
    }
    private enum DetailsRow: Int {
        case name, lastName, email, phone
    }
    
    private struct Constants {
        static let leadingSeparatorInset: CGFloat = 16
        static let phoneExplanation = NSLocalizedString("DeliveryDetails/PhoneExplanation", value: "Required by the postal service in case there are any issues with the delivery", comment: "Explanation of why the phone number is needed")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("DeliveryDetails/Title", value: "Delivery Details", comment: "Delivery Details screen title")
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        var detailsAreValid = true
        
        tableView.beginUpdates()
        detailsAreValid = check(firstNameTextField) && detailsAreValid
        detailsAreValid = check(lastNameTextField) && detailsAreValid
        detailsAreValid = checkEmail() && detailsAreValid
        detailsAreValid = checkPhone() && detailsAreValid
        tableView.endUpdates()
        
        if detailsAreValid {
            let details = DeliveryDetails()
            //TODO: set details
            
            details.saveDetailsAsLatest()
            navigationController?.popViewController(animated: true)
        }
    }
    
    func check(_ textField: UITextField) -> Bool {
        if textField.text?.isEmpty ?? true {
            textField.text = UserInputTableViewCell.Constants.requiredText
            textField.textColor = UserInputTableViewCell.Constants.errorColor
            return false
        }
        
        return true
    }
    
    func checkEmail() -> Bool {
        guard check(emailTextField) else { return false }
        
        let emailCell = (tableView.cellForRow(at: IndexPath(row: DetailsRow.email.rawValue, section: 0)) as? UserInputTableViewCell)
        if let email = emailCell?.textField.text,
            !email.isValidEmailAddress() {
            emailCell?.errorMessage = NSLocalizedString("DeliveryDetails/Email is invalid", value: "Email is invalid", comment: "Error message saying that the email address is invalid")
            return false
        }
        
        return true
    }
    
    func checkPhone() -> Bool {
        guard check(phoneTextField) else { return false }
        
        let phoneCell = (tableView.cellForRow(at: IndexPath(row: DetailsRow.phone.rawValue, section: 0)) as? UserInputTableViewCell)
        if let phone = phoneCell?.textField.text,
            phone.count < DeliveryDetails.minPhoneNumberLength {
            phoneCell?.errorMessage = NSLocalizedString("DeliveryDetails/Phone is invalid", value: "Phone is invalid", comment: "Error message saying that the phone number is invalid")
            return false
        }
        
        return true
    }
    
    func textField(after textField: UITextField) -> UITextField? {
        if textField === firstNameTextField {
            return lastNameTextField
            
        } else if textField === lastNameTextField {
            return emailTextField
        } else if textField === emailTextField {
            return phoneTextField
        }
        
        return nil
    }
    
    @IBAction func addAddress() {
        edit(address: Address())
    }
    
    func edit(address: Address) {
        guard let storyboard = storyboard,
            let addressVc = storyboard.instantiateViewController(withIdentifier: "AddressTableViewController") as? AddressTableViewController
            else { return }
        addressVc.delegate = self
        addressVc.address = address
        navigationController?.pushViewController(addressVc, animated: true)
    }
    
}

extension DeliveryDetailsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        
        switch section {
        case .details:
            return 4
        case .deliveryAddress:
            return ProductManager.shared.deliveryDetails?.address == nil ? 1 : 2
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let section = Section(rawValue: section) else { return nil }
        
        switch section {
        case .details:
            return NSLocalizedString("DeliveryDetails/DetailsHeader", value: "Details", comment: "Details section header")
        case .deliveryAddress:
            return NSLocalizedString("DeliveryDetails/DetailsHeader", value: "Delivery Address", comment: "Delivery Address section header")
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let section = Section(rawValue: indexPath.section) else { return UITableViewCell() }
        
        switch section {
        case .details:
            guard let row = DetailsRow(rawValue: indexPath.row) else { break }
            let cell = tableView.dequeueReusableCell(withIdentifier: "userInput", for: indexPath) as! UserInputTableViewCell
            switch row {
            case .name:
                cell.label.text = NSLocalizedString("DeliveryDetails/Name", value: "Name", comment: "Delivery Details screen first name textfield title")
                cell.message = nil
                cell.textField.textContentType = .givenName
                cell.textField.keyboardType = .default
                cell.textField.returnKeyType = .next
                cell.textField.autocapitalizationType = .words
                cell.topSeparator.isHidden = false
                cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
                firstNameTextField = cell.textField
            case .lastName:
                cell.label.text = NSLocalizedString("DeliveryDetails/LastName", value: "Last Name", comment: "Delivery Details screen last name textfield title")
                cell.message = nil
                cell.textField.textContentType = .familyName
                cell.textField.keyboardType = .default
                cell.textField.returnKeyType = .next
                cell.textField.autocapitalizationType = .words
                cell.topSeparator.isHidden = true
                cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
                lastNameTextField = cell.textField
            case .email:
                cell.label.text = NSLocalizedString("DeliveryDetails/Email", value: "Email", comment: "Delivery Details screen Email textfield title")
                cell.message = nil
                cell.textField.textContentType = .emailAddress
                cell.textField.keyboardType = .emailAddress
                cell.textField.returnKeyType = .next
                cell.textField.autocapitalizationType = .none
                cell.topSeparator.isHidden = true
                cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
                emailTextField = cell.textField
            case .phone:
                cell.label.text = NSLocalizedString("DeliveryDetails/Phone", value: "Phone", comment: "Delivery Details screen Phone textfield title")
                cell.message = Constants.phoneExplanation
                cell.textField.textContentType = .telephoneNumber
                cell.textField.keyboardType = .phonePad
                cell.textField.returnKeyType = .done
                cell.topSeparator.isHidden = true
                cell.separatorLeadingConstraint.constant = 0
                phoneTextField = cell.textField
            }
            return cell
        case .deliveryAddress:
            if ProductManager.shared.deliveryDetails != nil && indexPath.item == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: DeliveryAddressTableViewCell.reuseIdentifier, for: indexPath) as! DeliveryAddressTableViewCell
                if let address = details.address, address.isValid {
                    cell.topLabel.text = address.line1
                    cell.bottomLabel.text = address.descriptionWithoutLine1()
                }
                return cell
            }
            else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "AddDeliveryAddressCell", for: indexPath) as! UserInputTableViewCell
                cell.message = nil
                cell.topSeparator.isHidden = indexPath.row > 0
                return cell
            }
        }
        
        return UITableViewCell()
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Section.deliveryAddress.rawValue && (indexPath.item == 1 || (indexPath.item == 0 && ProductManager.shared.deliveryDetails?.address == nil)) {
            performSegue(withIdentifier: "AddressSegue", sender: nil)
            return
        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? UserInputTableViewCell {
            cell.textField.becomeFirstResponder()
        }
    }
    
}

extension DeliveryDetailsTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == UserInputTableViewCell.Constants.requiredText {
            textField.text = nil
        }
        
        tableView.beginUpdates()
        if textField === phoneTextField {
            let cell = (tableView.cellForRow(at: IndexPath(row: DetailsRow.phone.rawValue, section: 0)) as! UserInputTableViewCell)
            cell.message = Constants.phoneExplanation
        }
        else if textField === emailTextField {
            let cell = (tableView.cellForRow(at: IndexPath(row: DetailsRow.email.rawValue, section: 0)) as! UserInputTableViewCell)
            cell.message = nil
        }
        tableView.endUpdates()
        
        textField.textColor = .black
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        tableView.beginUpdates()
        if textField === firstNameTextField {
            _ = check(textField)
        } else if textField === lastNameTextField {
            _ = check(textField)
        } else if textField === emailTextField {
            _ = checkEmail()
        } else if textField == phoneTextField {
            _ = checkPhone()
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
}

extension DeliveryDetailsTableViewController: AddressTableViewControllerDelegate {
    
    func addressTableViewControllerDidSave(address: Address) {
        details.address = address
    }
    
}
