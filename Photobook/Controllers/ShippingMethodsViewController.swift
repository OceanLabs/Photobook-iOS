//
//  ShippingMethodsViewController.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 10/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

protocol ShippingMethodsDelegate: class {
    func didTapToDismissShippingMethods()
}

class ShippingMethodsViewController: UIViewController {
    
    private struct Constants {
        static let leadingSeparatorInset: CGFloat = 16
    }
    
    weak var delegate: ShippingMethodsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("ShippingMethods/Title", value: "Shipping Method", comment: "Shipping method selection screen title")
        
        if OrderManager.shared.basketOrder.shippingMethod == nil {
            OrderManager.shared.basketOrder.shippingMethod = OrderManager.shared.basketOrder.cachedCost?.shippingMethods?.first?.id
        }
    }
    
    @IBOutlet private weak var tableView: UITableView!
    
    @IBAction private func tappedCloseButton(_ sender: UIBarButtonItem) {
        delegate?.didTapToDismissShippingMethods()
    }
}

extension ShippingMethodsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let shippingMethodsCount = OrderManager.shared.basketOrder.cachedCost?.shippingMethods?.count {
            return shippingMethodsCount
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShippingMethodTableViewCell.reuseIdentifier, for: indexPath) as! ShippingMethodTableViewCell
        
        let shippingMethods = OrderManager.shared.basketOrder.cachedCost!.shippingMethods!
        let shippingMethod = shippingMethods[indexPath.row]
        
        cell.method = shippingMethod.name
        cell.deliveryTime = shippingMethod.deliveryTime
        cell.cost = shippingMethod.shippingCostFormatted
        
        let selected = OrderManager.shared.basketOrder.shippingMethod == shippingMethod.id
        cell.ticked = selected
        cell.separatorLeadingConstraint.constant = indexPath.row == shippingMethods.count - 1 ? 0.0 : Constants.leadingSeparatorInset
        cell.topSeparator.isHidden = indexPath.row != 0
        cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + "\(shippingMethod.name). \(shippingMethod.deliveryTime). \(shippingMethod.shippingCostFormatted)"
        cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShippingMethodHeaderTableViewCell.reuseIdentifier) as? ShippingMethodHeaderTableViewCell
        cell?.label.text = OrderManager.shared.basketOrder.cachedCost?.lineItems?[section].name
        
        return cell
    }
    
}

extension ShippingMethodsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shippingMethods = OrderManager.shared.basketOrder.cachedCost!.shippingMethods!
        OrderManager.shared.basketOrder.shippingMethod = shippingMethods[indexPath.row].id
        
        tableView.reloadData()
    }
    
}
