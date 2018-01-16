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
    
    var orderManager:OrderManager!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        orderManager = OrderManager()
        
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        getProductPreviewImage { (success) in
            
        }
    }
    
    private func getProductPreviewImage(_ completion:(_ success:Bool) -> Void) {
        let imageUrlString = "https://i.pinimg.com/564x/6c/77/e1/6c77e17a9f9e889f8d971258dddd0a54--radiohead-logo-ide-bagus.jpg"
        let imageWidth = Int(previewImageView.frame.size.width * UIScreen.main.scale)
        let imageHeight = Int(previewImageView.frame.size.height * UIScreen.main.scale)
        let urlString = "http://image.kite.ly/render/?image=" + imageUrlString + "&product_id=twill_tote_bag&variant=back2_melange_black&format=jpeg&debug=false&background=efefef" +
            "&size=\(imageWidth)x\(imageHeight)" +
            "&fill_mode=fit"
        UIImage.async(urlString) { (success, image) in
            self.previewImageView.image = image
        }
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
            orderManager.selectedUpsellOptions.insert(orderManager.upsellOptions[indexPath.row].identifier)
            tableView.reloadSections(IndexSet(integersIn: 0...1), with: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == sectionOptions {
            //handle changed upsell selection
            orderManager.selectedUpsellOptions.remove(orderManager.upsellOptions[indexPath.row].identifier)
            tableView.reloadSections(IndexSet(integersIn: 0...1), with: .none)
        }
    }
}

extension OrderSummaryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if orderManager.initialProduct == nil {
            return 0
        }
        
        switch section {
        case sectionDetails:
            return orderManager.priceDetails.count
        case sectionTotal:
            return orderManager.priceDetails.count>0 ? 1 : 0
        case sectionOptions:
            return orderManager.upsellOptions.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case sectionDetails:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryDetailTableViewCell", for: indexPath) as! OrderSummaryDetailTableViewCell
            cell.titleLabel.text = orderManager.priceDetails[indexPath.row].title
            cell.priceLabel.text = orderManager.priceDetails[indexPath.row].price.formatted
            return cell
        case sectionTotal:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryTotalTableViewCell", for: indexPath) as! OrderSummaryTotalTableViewCell
            if orderManager.priceDetails.count > 0 {
                var v:Float = 0
                for x in orderManager.priceDetails {
                    v = v + x.price.value
                }
                cell.priceLabel.text = Price(value: v, currencyCode: orderManager.priceDetails[0].price.currencyCode, currencySymbol: orderManager.priceDetails[0].price.currencySymbol).formatted
            }
            return cell
        case sectionOptions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryUpsellTableViewCell", for: indexPath) as! OrderSummaryUpsellTableViewCell
            cell.titleLabel?.text = "Upgrade to " + orderManager.upsellOptions[indexPath.row].title
            if orderManager.selectedUpsellOptions.contains(orderManager.upsellOptions[indexPath.row].identifier) {
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
