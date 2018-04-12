//
//  DeliveryDetailsTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

struct FormConstants {
    static let errorColor = UIColor(red:1, green:0.23, blue:0.19, alpha:1)
    static let requiredText = NSLocalizedString("UserInputRequired", value: "Required", comment: "User input required")
    static let minPhoneNumberLength = 5
}

class DeliveryDetailsTableViewController: UITableViewController {
    
    private var details = (OrderManager.shared.basketOrder.deliveryDetails?.copy() as? DeliveryDetails ?? DeliveryDetails.loadLatestDetails()) ?? DeliveryDetails()
    
    private weak var firstNameTextField: UITextField!
    private weak var lastNameTextField: UITextField!
    private weak var emailTextField: UITextField!
    private weak var phoneTextField: UITextField!
    
    private var editingAddress: Address?

    private enum Section: Int {
        case details, deliveryAddress
    }
    private enum DetailsRow: Int {
        case name, lastName, email, phone
    }
    private enum EntryType {
        case generic, email, phone
    }
    
    private struct Constants {
        static let leadingSeparatorInset: CGFloat = 16
        static let phoneExplanation = NSLocalizedString("DeliveryDetails/PhoneExplanation", value: "Required by the postal service in case there are any issues with the delivery", comment: "Explanation of why the phone number is needed")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("DeliveryDetails/Title", value: "Delivery Details", comment: "Delivery Details screen title")
        
        if details.address == nil {
            details.address = Address.savedAddresses.first
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        if identifier == "addressSegue", let addressVc = segue.destination as? AddressTableViewController {
            addressVc.delegate = self
            addressVc.address = sender as? Address ?? Address()
        }
        
    }
    
    @IBAction private func saveTapped(_ sender: Any) {
        view.endEditing(false)
        
        var detailsAreValid = true
        tableView.beginUpdates()
        detailsAreValid = check(firstNameTextField) && detailsAreValid
        detailsAreValid = check(lastNameTextField) && detailsAreValid
        detailsAreValid = check(emailTextField, type: .email) && detailsAreValid
        detailsAreValid = check(phoneTextField, type: .phone) && detailsAreValid
        detailsAreValid = checkAddress() && detailsAreValid
        tableView.endUpdates()
        
        if detailsAreValid {
            details.saveDetailsAsLatest()
            OrderManager.shared.basketOrder.deliveryDetails = details
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func check(_ textField: UITextField, type: EntryType? = nil) -> Bool {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let text = textField.text, !text.isEmpty, text != FormConstants.requiredText else {
            textField.text = FormConstants.requiredText
            textField.textColor = FormConstants.errorColor
            return false
        }
        
        switch type ?? .generic {
        case .email:
            let cell = (tableView.cellForRow(at: IndexPath(row: DetailsRow.email.rawValue, section: 0)) as? UserInputTableViewCell)
            if let text = cell?.textField.text,
                !text.isValidEmailAddress() {
                cell?.errorMessage = NSLocalizedString("DeliveryDetails/Email is invalid", value: "Email is invalid", comment: "Error message saying that the email address is invalid")
                cell?.textField.textColor = FormConstants.errorColor
                return false
            }
        case .phone:
            let cell = (tableView.cellForRow(at: IndexPath(row: DetailsRow.phone.rawValue, section: 0)) as? UserInputTableViewCell)
            if let text = cell?.textField.text,
                text.count < FormConstants.minPhoneNumberLength || text == FormConstants.requiredText {
                cell?.errorMessage = NSLocalizedString("DeliveryDetails/Phone is invalid", value: "Phone is invalid", comment: "Error message saying that the phone number is invalid")
                cell?.textField.textColor = FormConstants.errorColor
                return false
            }
        default:
            break
        }
        
        return true
    }
    
    private func checkAddress() -> Bool {
        if !(details.address?.isValid ?? false) {
            let cell = tableView.cellForRow(at: IndexPath(row: 0, section: Section.deliveryAddress.rawValue)) as? UserInputTableViewCell
            cell?.errorMessage = FormConstants.requiredText
            return false
        }
        
        return true
    }
    
    private func textField(after textField: UITextField) -> UITextField? {
        if textField === firstNameTextField {
            return lastNameTextField
            
        } else if textField === lastNameTextField {
            return emailTextField
        } else if textField === emailTextField {
            return phoneTextField
        }
        
        return nil
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
            return Address.savedAddresses.count + 1
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
                cell.label?.text = NSLocalizedString("DeliveryDetails/Name", value: "Name", comment: "Delivery Details screen first name textfield title")
                cell.message = nil
                cell.textField.textContentType = .givenName
                cell.textField.keyboardType = .default
                cell.textField.returnKeyType = .next
                cell.textField.autocapitalizationType = .words
                cell.textField.text = details.firstName
                cell.topSeparator.isHidden = false
                cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
                firstNameTextField = cell.textField
            case .lastName:
                cell.label?.text = NSLocalizedString("DeliveryDetails/LastName", value: "Last Name", comment: "Delivery Details screen last name textfield title")
                cell.message = nil
                cell.textField.textContentType = .familyName
                cell.textField.keyboardType = .default
                cell.textField.returnKeyType = .next
                cell.textField.autocapitalizationType = .words
                cell.textField.text = details.lastName
                cell.topSeparator.isHidden = true
                cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
                lastNameTextField = cell.textField
            case .email:
                cell.label?.text = NSLocalizedString("DeliveryDetails/Email", value: "Email", comment: "Delivery Details screen Email textfield title")
                cell.message = nil
                cell.textField.textContentType = .emailAddress
                cell.textField.keyboardType = .emailAddress
                cell.textField.returnKeyType = .next
                cell.textField.autocapitalizationType = .none
                cell.textField.text = details.email
                cell.topSeparator.isHidden = true
                cell.separatorLeadingConstraint.constant = Constants.leadingSeparatorInset
                emailTextField = cell.textField
            case .phone:
                cell.label?.text = NSLocalizedString("DeliveryDetails/Phone", value: "Phone", comment: "Delivery Details screen Phone textfield title")
                cell.message = Constants.phoneExplanation
                cell.textField.textContentType = .telephoneNumber
                cell.textField.keyboardType = .phonePad
                cell.textField.returnKeyType = .done
                cell.textField.text = details.phone
                cell.topSeparator.isHidden = true
                cell.separatorLeadingConstraint.constant = 0
                phoneTextField = cell.textField
            }
            return cell
        case .deliveryAddress:
            if indexPath.item < Address.savedAddresses.count {
                let cell = tableView.dequeueReusableCell(withIdentifier: DeliveryAddressTableViewCell.reuseIdentifier, for: indexPath) as! DeliveryAddressTableViewCell
                let address = Address.savedAddresses[indexPath.item]
                cell.topLabel.text = address.line1
                cell.bottomLabel.text = address.descriptionWithoutLine1()
                cell.checkmark.isHidden = address != details.address
                cell.topSeparator.isHidden = indexPath.row != 0
                
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
        if indexPath.section == Section.deliveryAddress.rawValue && indexPath.item < Address.savedAddresses.count {
            details.address = Address.savedAddresses[indexPath.item]
            tableView.reloadData()
        } else if indexPath.section == Section.deliveryAddress.rawValue {
            performSegue(withIdentifier: "addressSegue", sender: nil)
        } else if let cell = tableView.cellForRow(at: indexPath) as? UserInputTableViewCell {
            cell.textField.becomeFirstResponder()
        }
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        editingAddress = Address.savedAddresses[indexPath.item]
        performSegue(withIdentifier: "addressSegue", sender: editingAddress?.copy())
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == Section.deliveryAddress.rawValue,
            indexPath.row < Address.savedAddresses.count
            else { return false }
        
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let address = Address.savedAddresses[indexPath.item]
        address.removeFromSavedAddresses()
        
        if details.address == address {
            details.address = Address.savedAddresses.first
        }
        
        tableView.reloadSections(IndexSet(integer: Section.deliveryAddress.rawValue), with: .automatic)
    }
    
}

extension DeliveryDetailsTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == FormConstants.requiredText {
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
        tableView.beginUpdates()
        if textField === firstNameTextField {
            _ = check(textField)
            details.firstName = textField.text
        } else if textField === lastNameTextField {
            _ = check(textField)
            details.lastName = textField.text
        } else if textField === emailTextField {
            _ = check(emailTextField, type: .email)
            details.email = textField.text
        } else if textField == phoneTextField {
            _ = check(phoneTextField, type: .phone)
            details.phone = textField.text
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
        
        if let index = Address.savedAddresses.index(where: { $0 == editingAddress }) {
            Address.savedAddresses.remove(at: index)
            Address.savedAddresses.insert(address, at: index)
            Address.saveAddresses()
        }
        else {
            address.addToSavedAddresses()
        }
        
        tableView.reloadSections(IndexSet(integer: Section.deliveryAddress.rawValue), with: .none)
    }
    
}
