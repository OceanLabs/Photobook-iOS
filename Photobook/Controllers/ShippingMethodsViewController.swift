//
//  ShippingMethodsViewController.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 10/07/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import UIKit

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
    
    private lazy var sectionTitles: [String] = order.cost?.lineItems.map({ $0.name }) ?? []
    private lazy var countryCode = order.deliveryDetails?.address?.country.codeAlpha3 ?? Country.countryForCurrentLocale().codeAlpha3
    
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return order.products.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let regionCode = order.products[section].template.countryToRegionMapping?[countryCode],
            let shippingMethods = order.products[section].template.availableShippingMethods?[regionCode]
            else {
                return 0
        }
        return shippingMethods.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShippingMethodTableViewCell.reuseIdentifier, for: indexPath) as! ShippingMethodTableViewCell
        
        guard let regionCode = order.products[indexPath.section].template.countryToRegionMapping?[countryCode],
            let shippingMethod = order.products[indexPath.section].template.availableShippingMethods?[regionCode]?[indexPath.row] else {
            return cell
        }
        
        cell.method = shippingMethod.name
        cell.deliveryTime = shippingMethod.deliveryTime
        cell.cost = shippingMethod.price.formatted
        
        var selected = false
        if let selectedMethod = order.products[indexPath.section].selectedShippingMethod {
            selected = selectedMethod.id == shippingMethod.id
        }
        cell.ticked = selected
        cell.separatorLeadingConstraint.constant = indexPath.row == order.products[indexPath.section].template.availableShippingMethods!.count - 1 ? 0.0 : Constants.leadingSeparatorInset
        cell.topSeparator.isHidden = indexPath.row != 0
        cell.accessibilityLabel = (selected ? CommonLocalizedStrings.accessibilityListItemSelected : "") + "\(shippingMethod.name). \(shippingMethod.deliveryTime). \(shippingMethod.price.formatted)"
        cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = tableView.dequeueReusableCell(withIdentifier: ShippingMethodHeaderTableViewCell.reuseIdentifier) as? ShippingMethodHeaderTableViewCell
        cell?.label.text = sectionTitles[section]
        
        return cell
    }
    
}

extension ShippingMethodsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = order.products[indexPath.section]
        if let regionCode = product.template.countryToRegionMapping?[countryCode] {
            product.selectedShippingMethod = product.template.availableShippingMethods?[regionCode]?[indexPath.item]
        }
        
        tableView.reloadData()
    }
    
}
