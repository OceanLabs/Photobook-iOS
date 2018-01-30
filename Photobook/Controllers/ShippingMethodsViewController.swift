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
        
        if ProductManager.shared.shippingMethod == nil {
            ProductManager.shared.shippingMethod = ProductManager.shared.cachedCost?.shippingMethods?.first?.id
        }
    }
    
    @IBOutlet private weak var tableView: UITableView!
    
    @IBAction private func tappedCloseButton(_ sender: UIBarButtonItem) {
        delegate?.didTapToDismissShippingMethods()
    }
}

extension ShippingMethodsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let shippingMethodsCount = ProductManager.shared.cachedCost?.shippingMethods?.count {
            return shippingMethodsCount
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShippingMethodTableViewCell.reuseIdentifier, for: indexPath) as! ShippingMethodTableViewCell
        
        let shippingMethods = ProductManager.shared.cachedCost!.shippingMethods!
        let shippingMethod = shippingMethods[indexPath.row]
        
        cell.method = shippingMethod.name
        cell.deliveryTime = shippingMethod.deliveryTime
        cell.cost = shippingMethod.shippingCostFormatted
        cell.ticked = ProductManager.shared.shippingMethod == shippingMethod.id
        cell.separatorLeadingConstraint.constant = indexPath.row == shippingMethods.count - 1 ? 0.0 : Constants.leadingSeparatorInset
        cell.topSeparator.isHidden = indexPath.row != 0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShippingMethodHeaderTableViewCell.reuseIdentifier) as? ShippingMethodHeaderTableViewCell
        cell?.label.text = ProductManager.shared.cachedCost?.lineItems?[section].name
        
        return cell
    }
    
}

extension ShippingMethodsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shippingMethods = ProductManager.shared.cachedCost!.shippingMethods!
        ProductManager.shared.shippingMethod = shippingMethods[indexPath.row].id
        
        tableView.reloadData()
    }
    
}
