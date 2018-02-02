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
    func orderSummaryManager(_ manager: OrderSummaryManager, didUpdate success: Bool) {
        if success {
            tableView.reloadData()
            previewImageView.image = orderSummaryManager.previewImage
        } else {
            print("OrderSummaryViewController: Updating summary failed")
        }
        
        emptyScreenViewController.hide(animated: true)
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
            orderSummaryManager.selectedUpsellOptions.insert(orderSummaryManager.upsellOptions![indexPath.row])
            orderSummaryManager.refresh()
            emptyScreenViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"), activity: true)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == sectionOptions {
            //handle changed upsell selection
            orderSummaryManager.selectedUpsellOptions.remove(orderSummaryManager.upsellOptions![indexPath.row])
            orderSummaryManager.refresh()
            emptyScreenViewController.show(message: NSLocalizedString("OrderSummary/Loading", value: "Loading order details", comment: "Loading product summary"), activity: true)
        }
    }
}

extension OrderSummaryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let summary = orderSummaryManager.summary else {
            return 0
        }
        
        switch section {
        case sectionDetails:
            return summary.details.count
        case sectionTotal:
            return summary.details.count>0 ? 1 : 0
        case sectionOptions:
            if let upsellOptions = orderSummaryManager.upsellOptions { return upsellOptions.count }
            else { return 0 }
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case sectionDetails:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryDetailTableViewCell", for: indexPath) as! OrderSummaryDetailTableViewCell
            cell.titleLabel.text = orderSummaryManager.summary?.details[indexPath.row].name
            cell.priceLabel.text = orderSummaryManager.summary?.details[indexPath.row].price.formatted
            return cell
        case sectionTotal:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryTotalTableViewCell", for: indexPath) as! OrderSummaryTotalTableViewCell
            let summary = orderSummaryManager.summary!
            if summary.details.count > 0 {
                var v:Float = 0
                for x in summary.details {
                    v = v + x.price.value
                }
                cell.priceLabel.text = Price(value: v, currencyCode: summary.details[0].price.currencyCode).formatted
            }
            return cell
        case sectionOptions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryUpsellTableViewCell", for: indexPath) as! OrderSummaryUpsellTableViewCell
            cell.titleLabel?.text = "Upgrade to " + orderSummaryManager.upsellOptions![indexPath.row].displayName
            if orderSummaryManager.selectedUpsellOptions.contains(orderSummaryManager.upsellOptions![indexPath.row]) {
                tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
            }
            return cell
        default:
            return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
    }
}
