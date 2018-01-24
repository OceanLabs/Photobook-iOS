//
//  AddressTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 24/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

protocol AddressTableViewControllerDelegate: class {
    func addressTableViewControllerDidSave(address: Address)
}

class AddressTableViewController: UITableViewController {
    
    var address: Address!
    
    weak var delegate: AddressTableViewControllerDelegate?
    
    weak var line1TextField: UITextField!
    weak var line2TextField: UITextField!
    weak var cityTextField: UITextField!
    weak var countyOrStateTextField: UITextField!
    weak var zipOrPostcodeTextField: UITextField!

    private enum Row: Int {
        case line1, line2, city, countyOrState, zipOrPostcode, country
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("AddressEdit/Title", value: "Address", comment: "Address entry screen title")
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        var detailsAreValid = true
        
        detailsAreValid = check(line1TextField) && detailsAreValid
        detailsAreValid = check(cityTextField) && detailsAreValid
        detailsAreValid = check(zipOrPostcodeTextField) && detailsAreValid
        
        if detailsAreValid {
            //TODO: set details to adrees
            
            self.delegate?.addressTableViewControllerDidSave(address: address)
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
    
    func textField(after textField: UITextField) -> UITextField? {
        if textField === line1TextField {
            return line2TextField
        } else if textField === line2TextField {
            return cityTextField
        } else if textField === cityTextField {
            return countyOrStateTextField
        } else if textField === countyOrStateTextField {
            return zipOrPostcodeTextField
        }
        
        return nil
    }
    
}

extension AddressTableViewController {
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("AddressEntry/DetailsHeader", value: "Details", comment: "Address Entry Details section header")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let row = Row(rawValue: indexPath.row) else { return UITableViewCell() }
        let cell = tableView.dequeueReusableCell(withIdentifier: "userInput", for: indexPath) as! AddressFieldTableViewCell
        switch row {
        case .line1:
            cell.label.text = NSLocalizedString("AddressEntry/Line1", value: "Line1", comment: "Address Entry screen line1 textfield title")
            cell.textField.textContentType = .streetAddressLine1
            cell.textField.keyboardType = .default
            cell.textField.returnKeyType = .next
            cell.textField.autocapitalizationType = .words
            cell.textField.isUserInteractionEnabled = true
            cell.textField.placeholder = UserInputTableViewCell.Constants.requiredText
            line1TextField = cell.textField
        case .line2:
            cell.label.text = NSLocalizedString("AddressEntry/Line2", value: "Line2", comment: "Address Entry screen line2 textfield title")
            cell.textField.textContentType = .streetAddressLine1
            cell.textField.keyboardType = .default
            cell.textField.returnKeyType = .next
            cell.textField.autocapitalizationType = .words
            cell.textField.isUserInteractionEnabled = true
            cell.textField.placeholder = nil
            line2TextField = cell.textField
        case .city:
            cell.label.text = NSLocalizedString("AddressEntry/City", value: "City", comment: "Address Entry screen City textfield title")
            cell.textField.textContentType = .addressCity
            cell.textField.keyboardType = .default
            cell.textField.returnKeyType = .next
            cell.textField.autocapitalizationType = .words
            cell.textField.isUserInteractionEnabled = true
            cell.textField.placeholder = UserInputTableViewCell.Constants.requiredText
            cityTextField = cell.textField
        case .countyOrState:
            cell.label.text = NSLocalizedString("AddressEntry/County", value: "County", comment: "Address Entry screen County textfield title")
            cell.textField.textContentType = .addressState
            cell.textField.keyboardType = .default
            cell.textField.returnKeyType = .next
            cell.textField.autocapitalizationType = .words
            cell.textField.isUserInteractionEnabled = true
            cell.textField.placeholder = nil
            countyOrStateTextField = cell.textField
        case .zipOrPostcode:
            cell.label.text = NSLocalizedString("AddressEntry/Postcode", value: "Postcode", comment: "Address Entry screen Postcode textfield title")
            cell.textField.textContentType = .postalCode
            cell.textField.keyboardType = .default
            cell.textField.returnKeyType = .done
            cell.textField.autocapitalizationType = .allCharacters
            cell.textField.isUserInteractionEnabled = true
            cell.textField.placeholder = UserInputTableViewCell.Constants.requiredText
            zipOrPostcodeTextField = cell.textField
        case .country:
            cell.label.text = NSLocalizedString("AddressEntry/Country", value: "Country", comment: "Address Entry screen Country textfield title")
            cell.textField.isUserInteractionEnabled = false
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AddressFieldTableViewCell else { return }
        
        if cell.textField.isUserInteractionEnabled{
            cell.textField.becomeFirstResponder()
        }
        else {
            guard let storyboard = storyboard,
                let countryVc = storyboard.instantiateViewController(withIdentifier: "CountryPickerTableViewController") as? CountryPickerTableViewController
                else { return }
            countryVc.delegate = self
            countryVc.selectedCountry = address.country
            navigationController?.pushViewController(countryVc, animated: true)
        }
        
        
    }
    
}

extension AddressTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == UserInputTableViewCell.Constants.requiredText {
            textField.text = nil
        }
        
        textField.textColor = .black
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        if textField === line1TextField || textField === cityTextField || textField === zipOrPostcodeTextField {
            _ = check(textField)
        }
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

extension AddressTableViewController: CountryPickerTableViewControllerDelegate {
    
    func countryPickerDidPick(country: Country) {
        address.country = country
    }
    
}

