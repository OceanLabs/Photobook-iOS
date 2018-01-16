//
//  OrderManager.swift
//  Photobook
//
//  Created by Julian Gruber on 15/01/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

typealias PriceDetail = (title:String, price:Price)
typealias UpsellOption = (identifier:String, title:String)

class OrderManager {

    public var priceDetails:[PriceDetail] = []
    public var upsellOptions:[UpsellOption] = []
    
    public var initialProduct:Photobook! //original product provided by previous UX
    public var selectedUpsellOptions:Set<String> = []
    
    public var product:Photobook? //product to place the order with. Reflects user's selected upsell options.
    
    init() {
        initialProduct = getMockPhotobook()
        upsellOptions = getMockUpsellOptions()
        priceDetails = getMockPricelist()
        refreshProduct()
    }
    
    init(withProduct product:Photobook) {
        initialProduct = getMockPhotobook()
        upsellOptions = getMockUpsellOptions()
        priceDetails = getMockPricelist()
        refreshProduct()
    }
    
    func refreshProduct() {
        
    }
    
    func getMockPhotobook() -> Photobook {
        let validDictionary = [
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
            ] as [String: AnyObject]
        
        return Photobook.parse(validDictionary)!
    }
    
    func getMockUpsellOptions() -> [UpsellOption] {
        let dictionaries = [
        [
            "id": "size",
            "title": "larger size (210x210)"
            ],
        [
            "id": "finish",
            "title": "gloss finish"
            ]
        ] as [[String: AnyObject]]
        
        var upsellOptions = [UpsellOption]()
        for dict in dictionaries {
            if let identifier = dict["id"] as? String, let title = dict["title"] as? String {
                upsellOptions.append((identifier, title))
            }
        }
        
        return upsellOptions
    }
    
    func getMockPricelist() -> [PriceDetail] {
        let validDictionary = ["currency_code": "GBP",
                               "currency_symbol": "£",
                               "details": [
                                [
                                    "title": "Square (210x210)",
                                    "price": 30
                                    ],
                                 [
                                    "title": "Gloss finish",
                                    "price": 5
                                    ],
                                 [
                                    "title": "2 extra pages",
                                    "price": 3
                                    ]]] as [String: Any]
        
        var priceDetails = [PriceDetail]()
        guard let currencyCode = validDictionary["currency_code"] as? String,
            let currencySymbol = validDictionary["currency_symbol"] as? String,
            let dictionaries = validDictionary["details"] as? [[String:Any]] else {
                return priceDetails
        }
        
        for dict in dictionaries {
            if let title = dict["title"] as? String, let price = dict["price"] as? Int {
                priceDetails.append((title, Price(value: Float(price), currencyCode: currencyCode, currencySymbol: currencySymbol)))
            }
        }
        
        return priceDetails
    }
}
