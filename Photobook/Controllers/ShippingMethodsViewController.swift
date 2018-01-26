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
    
    fileprivate struct Constants {
        static let titleHeight: CGFloat = 50.0
        static let methodHeight: CGFloat = 52.0
    }
    
    weak var delegate: ShippingMethodsDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("ShippingMethods/Title", value: "Shipping Method", comment: "Shipping method selection screen title")
    }
    
    @IBOutlet fileprivate weak var tableView: UITableView! {
        didSet {
            tableView.rowHeight = Constants.methodHeight
            tableView.sectionHeaderHeight = Constants.titleHeight
            tableView.reloadData()
        }
    }
    
    @IBAction func tappedCloseButton(_ sender: UIBarButtonItem) {
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
        cell.separator.alpha = indexPath.row == shippingMethods.count - 1 ? 0.0 : 1.0
        
        return cell
    }
    
}

extension ShippingMethodsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let shippingMethods = ProductManager.shared.cachedCost!.shippingMethods!
        ProductManager.shared.shippingMethod = shippingMethods[indexPath.row].id
        
        tableView.reloadData()
    }
    
}
