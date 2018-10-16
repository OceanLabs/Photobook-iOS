//
//  DeliveryDetailsTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class DeliveryDetailsTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("DeliveryDetails/Title", value: "Delivery Details", comment: "Delivery Details screen title")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        if identifier == "addressSegue", let addressViewController = segue.destination as? AddressTableViewController {
            guard let dictionary = sender as? [String: Any] else { return }
            addressViewController.deliveryDetails = dictionary["details"] as? DeliveryDetails ?? DeliveryDetails()
            addressViewController.index = dictionary["index"] as? Int
            addressViewController.delegate = self
        }
    }
}

extension DeliveryDetailsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DeliveryDetails.savedDeliveryDetails.count + 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("DeliveryDetails/DetailsHeader", value: "Delivery Address", comment: "Delivery Address section header")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.item < DeliveryDetails.savedDeliveryDetails.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: DeliveryAddressTableViewCell.reuseIdentifier, for: indexPath) as! DeliveryAddressTableViewCell
            let details = DeliveryDetails.savedDeliveryDetails[indexPath.item]
            cell.topLabel.text = details.line1
            cell.bottomLabel.text = details.descriptionWithoutLine1()
            
            cell.checkmark.isHidden = !details.selected
            cell.topSeparator.isHidden = indexPath.row != 0
            cell.accessibilityLabel = (details.selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + (details.line1 ?? "") + ", " + details.descriptionWithoutLine1()
            cell.accessibilityHint = details.selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddDeliveryAddressCell", for: indexPath) as! UserInputTableViewCell
        cell.message = nil
        cell.topSeparator.isHidden = indexPath.row > 0
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.item < DeliveryDetails.savedDeliveryDetails.count {
            let details = DeliveryDetails.savedDeliveryDetails[indexPath.item]
            DeliveryDetails.select(details)
            
            OrderManager.shared.basketOrder.deliveryDetails = details
            
            tableView.reloadData()
            
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
            return
        }
        performSegue(withIdentifier: "addressSegue", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let details = DeliveryDetails.savedDeliveryDetails[indexPath.item]
        performSegue(withIdentifier: "addressSegue", sender: ["details": details.copy(), "index": indexPath.item])
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < DeliveryDetails.savedDeliveryDetails.count else { return false }
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let details = DeliveryDetails.savedDeliveryDetails[indexPath.item]
        DeliveryDetails.remove(details)
        
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

extension DeliveryDetailsTableViewController: AddressTableViewControllerDelegate {
    
    func addressTableViewControllerDidEdit() {
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
        navigationController?.popViewController(animated: true)
    }
}
