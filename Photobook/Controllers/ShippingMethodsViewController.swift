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
        
        static let stringLoading = NSLocalizedString("ShippingMethodsViewController/Loading", value: "Loading shipping details", comment: "Loading shipping methods")
        static let stringLoadingFail = NSLocalizedString("ShippingMethodsViewController/LoadingFail", value: "Couldn't load shipping details", comment: "When loading shipping methods fails")
        
        static let leadingSeparatorInset: CGFloat = 16
    }
    
    weak var delegate: ShippingMethodsDelegate?
    
    private lazy var progressOverlayViewController: ProgressOverlayViewController = {
        return ProgressOverlayViewController.progressOverlay(parent: self)
    }()
    
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    
    var order: Order {
        get {
            return OrderManager.shared.basketOrder
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = NSLocalizedString("ShippingMethods/Title", value: "Shipping Method", comment: "Shipping method selection screen title")
    }
    
    @IBOutlet private weak var tableView: UITableView!
    
    @IBAction private func tappedCloseButton(_ sender: UIBarButtonItem) {
        delegate?.didTapToDismissShippingMethods()
    }
}

extension ShippingMethodsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return OrderManager.shared.basketOrder.availableShippingMethods?.first?.count ?? 0 //TODO: currently only supports one section/product
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShippingMethodTableViewCell.reuseIdentifier, for: indexPath) as! ShippingMethodTableViewCell
        
        let shippingMethod = OrderManager.shared.basketOrder.availableShippingMethods![indexPath.section][indexPath.row]
        
        cell.method = shippingMethod.name
        cell.deliveryTime = shippingMethod.deliveryTime
        cell.cost = shippingMethod.price.formatted
        
        var selected = false
        if let selectedMethods = OrderManager.shared.basketOrder.selectedShippingMethods, selectedMethods.count > indexPath.section {
            selected = selectedMethods[indexPath.section].id == shippingMethod.id
        }
        cell.ticked = selected
        cell.separatorLeadingConstraint.constant = indexPath.row == OrderManager.shared.basketOrder.availableShippingMethods!.count - 1 ? 0.0 : Constants.leadingSeparatorInset
        cell.topSeparator.isHidden = indexPath.row != 0
        cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + "\(shippingMethod.name). \(shippingMethod.deliveryTime). \(shippingMethod.price.formatted)"
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
        order.setShippingMethod(indexPath.row, forSection: indexPath.section)
        
        tableView.reloadData()
    }
    
}
