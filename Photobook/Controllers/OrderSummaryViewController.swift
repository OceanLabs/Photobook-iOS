//
//  OrderSummaryViewController.swift
//  Photobook
//
//  Created by Julian Gruber on 05/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

class OrderSummaryViewController: UIViewController {
    
    private let sectionDetails = 0
    private let sectionTotal = 1
    private let sectionOptions = 2
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var previewImageView: UIImageView!
    
    private lazy var emptyScreenViewController: EmptyScreenViewController = {
        return EmptyScreenViewController.emptyScreen(parent: self)
    }()
    
    var orderSummaryManager:OrderSummaryManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        emptyScreenViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"), activity: true)
        
        orderSummaryManager = OrderSummaryManager()
        orderSummaryManager.delegate = self
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension OrderSummaryViewController: OrderSummaryManagerDelegate {
    func orderSummaryManagerDidUpdate(_ manager: OrderSummaryManager) {
        tableView.reloadData()
        previewImageView.image = orderSummaryManager.previewImage
        
        emptyScreenViewController.hide(animated: true)
    }
    
    func orderSummaryManagerPreviewImageSize(_ manager: OrderSummaryManager) -> CGSize {
        return previewImageView.frame.size
    }
}

extension OrderSummaryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case sectionDetails:
            return 35
        case sectionTotal:
            return 45
        case sectionOptions:
            return 63
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == sectionOptions {
            //handle changed upsell selection
            orderSummaryManager.selectedUpsellOptions.insert(orderSummaryManager.upsellOptions[indexPath.row].type)
            tableView.reloadSections(IndexSet(integersIn: 0...1), with: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == sectionOptions {
            //handle changed upsell selection
            orderSummaryManager.selectedUpsellOptions.remove(orderSummaryManager.upsellOptions[indexPath.row].type)
            tableView.reloadSections(IndexSet(integersIn: 0...1), with: .none)
        }
    }
}

extension OrderSummaryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if orderSummaryManager.product == nil {
            return 0
        }
        
        switch section {
        case sectionDetails:
            return orderSummaryManager.summary.count
        case sectionTotal:
            return orderSummaryManager.summary.count>0 ? 1 : 0
        case sectionOptions:
            return orderSummaryManager.upsellOptions.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case sectionDetails:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryDetailTableViewCell", for: indexPath) as! OrderSummaryDetailTableViewCell
            cell.titleLabel.text = orderSummaryManager.summary[indexPath.row].name
            cell.priceLabel.text = orderSummaryManager.summary[indexPath.row].price.formatted
            return cell
        case sectionTotal:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryTotalTableViewCell", for: indexPath) as! OrderSummaryTotalTableViewCell
            if orderSummaryManager.summary.count > 0 {
                var v:Float = 0
                for x in orderSummaryManager.summary {
                    v = v + x.price.value
                }
                cell.priceLabel.text = Price(value: v, currencyCode: orderSummaryManager.summary[0].price.currencyCode).formatted
            }
            return cell
        case sectionOptions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryUpsellTableViewCell", for: indexPath) as! OrderSummaryUpsellTableViewCell
            cell.titleLabel?.text = "Upgrade to " + orderSummaryManager.upsellOptions[indexPath.row].displayName
            if orderSummaryManager.selectedUpsellOptions.contains(orderSummaryManager.upsellOptions[indexPath.row].type) {
                cell.setSelected(true, animated: false)
            } else {
                cell.setSelected(false, animated: false)
            }
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
    }
}
