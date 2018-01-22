//
//  DeliveryDetailsTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 22/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class DeliveryDetailsTableViewController: UITableViewController {

    private enum Section: Int {
        case details, deliveryAddress
    }
    private enum DetailsRow: Int {
        case name, lastName, email, phone
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
            return ProductManager.shared.address == nil ? 1 : 2
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
                break
            case .lastName:
                break
            case .email:
                break
            case .phone:
                break
            }
            return cell
        case .deliveryAddress:
            if ProductManager.shared.address != nil && indexPath.item == 0 {
                break
            }
            else {
                return tableView.dequeueReusableCell(withIdentifier: "AddDeliveryAddressCell", for: indexPath)
            }
        }
        
        return UITableViewCell()
        
    }
    
    
}
