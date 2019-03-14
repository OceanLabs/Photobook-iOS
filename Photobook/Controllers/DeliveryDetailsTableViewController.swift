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

class DeliveryDetailsTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("DeliveryDetails/Title", value: "Delivery Details", comment: "Delivery Details screen title")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        
        if identifier == "addressSegue", let addressViewController = segue.destination as? AddressTableViewController {
            let dictionary = sender as? [String: Any] ?? [String: Any]()
            addressViewController.deliveryDetails = dictionary["details"] as? OLDeliveryDetails ?? OLDeliveryDetails()
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
        return OLDeliveryDetails.savedDeliveryDetails.count + 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString("DeliveryDetails/DetailsHeader", value: "Delivery Address", comment: "Delivery Address section header")
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.item < OLDeliveryDetails.savedDeliveryDetails.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: DeliveryAddressTableViewCell.reuseIdentifier, for: indexPath) as! DeliveryAddressTableViewCell
            let details = OLDeliveryDetails.savedDeliveryDetails[indexPath.item]
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
        if indexPath.item < OLDeliveryDetails.savedDeliveryDetails.count {
            let details = OLDeliveryDetails.savedDeliveryDetails[indexPath.item]
            OLDeliveryDetails.select(details)
            
            OrderManager.shared.basketOrder.deliveryDetails = details
            
            tableView.reloadData()
            
            UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: nil)
            return
        }
        performSegue(withIdentifier: "addressSegue", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let details = OLDeliveryDetails.savedDeliveryDetails[indexPath.item]
        performSegue(withIdentifier: "addressSegue", sender: ["details": details.copy(), "index": indexPath.item])
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.row < OLDeliveryDetails.savedDeliveryDetails.count else { return false }
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        
        let details = OLDeliveryDetails.savedDeliveryDetails[indexPath.item]
        OLDeliveryDetails.remove(details)
        
        tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
    }
}

extension DeliveryDetailsTableViewController: AddressTableViewControllerDelegate {
    
    func addressTableViewControllerDidEdit() {
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
        navigationController?.popViewController(animated: true)
    }
}
