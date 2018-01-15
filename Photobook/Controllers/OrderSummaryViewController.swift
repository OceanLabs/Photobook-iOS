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
    
    public var order:Order?
    public var priceDetails:[(title:String, price:Price)] = []
    public var upsellOptions:[(title:String, identifier:String)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let validDictionary = ([
            "id": 10,
            "name": "210 x 210",
            "pageWidth": 1000,
            "pageHeight": 400,
            "coverWidth": 1030,
            "coverHeight": 415,
            "cost": [ "EUR": 10.00 as Decimal, "USD": 12.00 as Decimal, "GBP": 9.00 as Decimal ],
            "costPerPage": [ "EUR": 1.00 as Decimal, "USD": 1.20 as Decimal, "GBP": 0.85 as Decimal ],
            "coverLayouts": [ 9, 10 ],
            "layouts": [ 10, 11, 12, 13 ]
            ]) as [String: AnyObject]
        order = Order(photobook: Photobook.parse(validDictionary)!, selectedUpsellOptions: [])
        upsellOptions = [("larger size", "size"), ("gloss finish", "finish")]
        priceDetails = [("Square 210x210", Price(value: 30, currencyCode: "GBP", currencySymbol: "£")),
                        ("2 extra pages", Price(value: 3, currencyCode: "GBP", currencySymbol: "£")),
                        ("Gloss finish", Price(value: 5, currencyCode: "GBP", currencySymbol: "£"))]
        
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
            order?.selectedUpsellOptions.insert(upsellOptions[indexPath.row].identifier)
            tableView.reloadSections(IndexSet(integersIn: 0...1), with: .none)
        } else {
            tableView.deselectRow(at: indexPath, animated: false)
        }
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if indexPath.section == sectionOptions {
            //handle changed upsell selection
            order?.selectedUpsellOptions.remove(upsellOptions[indexPath.row].identifier)
            tableView.reloadSections(IndexSet(integersIn: 0...1), with: .none)
        }
    }
}

extension OrderSummaryViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.order == nil {
            return 0
        }
        
        switch section {
        case sectionDetails:
            return priceDetails.count
        case sectionTotal:
            return priceDetails.count>0 ? 1 : 0
        case sectionOptions:
            return upsellOptions.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case sectionDetails:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryDetailTableViewCell", for: indexPath) as! OrderSummaryDetailTableViewCell
            cell.titleLabel.text = priceDetails[indexPath.row].title
            cell.priceLabel.text = priceDetails[indexPath.row].price.formatted
            return cell
        case sectionTotal:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryTotalTableViewCell", for: indexPath) as! OrderSummaryTotalTableViewCell
            if priceDetails.count > 0 {
                var v:Float = 0
                for x in priceDetails {
                    v = v + x.price.value
                }
                cell.priceLabel.text = Price(value: v, currencyCode: priceDetails[0].price.currencyCode, currencySymbol: priceDetails[0].price.currencySymbol).formatted
            }
            return cell
        case sectionOptions:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OrderSummaryUpsellTableViewCell", for: indexPath) as! OrderSummaryUpsellTableViewCell
            cell.titleLabel?.text = "Upgrade to " + upsellOptions[indexPath.row].title
            if let order = self.order, order.selectedUpsellOptions.contains(upsellOptions[indexPath.row].identifier) {
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
