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
    
    private weak var line1TextField: UITextField!
    private weak var line2TextField: UITextField!
    private weak var cityTextField: UITextField!
    private weak var stateOrCountyTextField: UITextField!
    private weak var zipOrPostcodeTextField: UITextField!

    private enum Row: Int {
        case line1, line2, city, stateOrCounty, zipOrPostcode, country
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("AddressEdit/Title", value: "Address", comment: "Address entry screen title")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        if identifier == "countryPickerSegue", let countryPicker = segue.destination as? CountryPickerTableViewController {
            countryPicker.delegate = self
            countryPicker.selectedCountry = sender as? Country
        }
        
    }
    
    @IBAction private func saveTapped(_ sender: Any) {
        var detailsAreValid = true
        
        detailsAreValid = check(line1TextField) && detailsAreValid
        detailsAreValid = check(cityTextField) && detailsAreValid
        detailsAreValid = check(zipOrPostcodeTextField) && detailsAreValid
        
        if detailsAreValid {
            address.line1 = line1TextField.text
            address.line2 = line2TextField.text
            address.city = cityTextField.text
            address.stateOrCounty = stateOrCountyTextField.text
            address.zipOrPostcode = zipOrPostcodeTextField.text
            
            self.delegate?.addressTableViewControllerDidSave(address: address)
            navigationController?.popViewController(animated: true)
        }
    }
    
    private func check(_ textField: UITextField) -> Bool {
        if textField.text?.isEmpty ?? true {
            textField.text = Global.Constants.requiredText
            textField.textColor = Global.Constants.errorColor
            return false
        }
        
        return true
    }
    
    private func textField(after textField: UITextField) -> UITextField? {
        if textField === line1TextField {
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
    
    private func configure(cell: AddressFieldTableViewCell, for row:Row) {
        
        cell.textField.keyboardType = .default
        cell.textField.isUserInteractionEnabled = true
        cell.textField.placeholder = nil
        cell.textField.autocapitalizationType = .words
        
        switch row {
        case .line1:
            cell.label.text = NSLocalizedString("AddressEntry/Line1", value: "Line1", comment: "Address Entry screen line1 textfield title")
            cell.textField.textContentType = .streetAddressLine1
            cell.textField.returnKeyType = .next
            cell.textField.placeholder = Global.Constants.requiredText
            cell.textField.text = address.line1
            line1TextField = cell.textField
        case .line2:
            cell.label.text = NSLocalizedString("AddressEntry/Line2", value: "Line2", comment: "Address Entry screen line2 textfield title")
            cell.textField.textContentType = .streetAddressLine1
            cell.textField.returnKeyType = .next
            cell.textField.text = address.line2
            line2TextField = cell.textField
        case .city:
            cell.label.text = NSLocalizedString("AddressEntry/City", value: "City", comment: "Address Entry screen City textfield title")
            cell.textField.textContentType = .addressCity
            cell.textField.returnKeyType = .next
            cell.textField.placeholder = Global.Constants.requiredText
            cell.textField.text = address.city
            cityTextField = cell.textField
        case .stateOrCounty:
            cell.label.text = NSLocalizedString("AddressEntry/County", value: "County", comment: "Address Entry screen County textfield title")
            cell.textField.textContentType = .addressState
            cell.textField.returnKeyType = .next
            cell.textField.text = address.stateOrCounty
            stateOrCountyTextField = cell.textField
        case .zipOrPostcode:
            cell.label.text = NSLocalizedString("AddressEntry/Postcode", value: "Postcode", comment: "Address Entry screen Postcode textfield title")
            cell.textField.textContentType = .postalCode
            cell.textField.returnKeyType = .done
            cell.textField.autocapitalizationType = .allCharacters
            cell.textField.placeholder = Global.Constants.requiredText
            cell.textField.text = address.zipOrPostcode
            zipOrPostcodeTextField = cell.textField
        case .country:
            cell.label.text = NSLocalizedString("AddressEntry/Country", value: "Country", comment: "Address Entry screen Country textfield title")
            cell.textField.isUserInteractionEnabled = false
            cell.textField.text = address.country.name
        }
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
        configure(cell: cell, for: row)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) as? AddressFieldTableViewCell else { return }
        
        if cell.textField.isUserInteractionEnabled{
            cell.textField.becomeFirstResponder()
        }
        else {
            performSegue(withIdentifier: "countryPickerSegue", sender: address.country)
        }
        
        
    }
    
}

extension AddressTableViewController: UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.text == Global.Constants.requiredText {
            textField.text = nil
        }
        
        textField.textColor = .black
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.text = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch textField {
        case line1TextField:
            _ = check(textField)
            address.line1 = line1TextField.text
        case line2TextField:
            address.line2 = line2TextField.text
        case cityTextField:
            _ = check(textField)
            address.city = cityTextField.text
        case stateOrCountyTextField:
            address.stateOrCounty = stateOrCountyTextField.text
        case zipOrPostcodeTextField:
            _ = check(textField)
            address.zipOrPostcode = zipOrPostcodeTextField.text
        default:
            break
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
        tableView.reloadRows(at: [IndexPath(row: Row.country.rawValue, section: 0)], with: .none)
    }
    
}

