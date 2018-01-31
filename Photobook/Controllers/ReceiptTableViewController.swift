//
//  ReceiptTableViewController.swift
//  Photobook
//
//  Created by Konstadinos Karayannis on 29/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class ReceiptTableViewController: UITableViewController {
    
    var cost: Cost? {
        return ProductManager.shared.cachedCost
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("Receipt/Title", value: "Purchased", comment: "Receipt screen title")
        navigationItem.leftBarButtonItem = UIBarButtonItem()
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    @IBAction func continueTapped(_ sender: UIBarButtonItem) {
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.popToRootViewController(animated: true)
    }
    
    enum Section: Int {
        case header, lineItems, footer
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == Section.lineItems.rawValue ? cost?.lineItems?.count ?? 0 : 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case Section.header.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptHeaderTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptHeaderTableViewCell
            cell.shippingMethodLabel.text = cost?.shippingMethod(id: ProductManager.shared.shippingMethod)?.name
            // TODO: Replace with order number
            cell.orderNumberLabel.text = "#1234"
            
            let deliveryDetails = ProductManager.shared.deliveryDetails
            var addressString = ""
            if let name = deliveryDetails?.fullName, !name.isEmpty { addressString += "\(name)\n"}
            if let line1 = deliveryDetails?.address?.line1, !line1.isEmpty { addressString += "\(line1)\n"}
            if let line2 = deliveryDetails?.address?.line2, !line2.isEmpty { addressString += "\(line2)\n"}
            if let city = deliveryDetails?.address?.city, !city.isEmpty { addressString += "\(city) "}
            if let postCode = deliveryDetails?.address?.zipOrPostcode, !postCode.isEmpty { addressString += "\(postCode)\n"}
            if let countryName = deliveryDetails?.address?.country.name, !countryName.isEmpty { addressString += "\(countryName)\n"}
            cell.shippingAddressLabel.text = addressString
            
            return cell
        case Section.lineItems.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptLineItemTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptLineItemTableViewCell
            cell.lineItemNameLabel.text = cost?.lineItems?[indexPath.row].name
            cell.lineItemCostLabel.text = cost?.lineItems?[indexPath.row].formattedCost
            return cell
        case Section.footer.rawValue:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReceiptFooterTableViewCell.reuseIdentifier, for: indexPath) as! ReceiptFooterTableViewCell
            cell.totalCostLabel.text = cost?.shippingMethod(id: ProductManager.shared.shippingMethod)?.totalCostFormatted
            return cell
        default:
            return UITableViewCell()
        }
    }

}
