////
//  OrderSummaryManager.swift
//  Photobook
//
//  Created by Julian Gruber on 02/02/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//

import UIKit

struct OrdersNotificationName {
    static let orderWasCreated = Notification.Name("ly.kite.sdk.orderWasCreated")
    static let orderWasSuccessful = Notification.Name("ly.kite.sdk.orderWasSuccessful")
}

class OrderManager {
    
    struct Storage {
        static let photobookDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/Photobook/")
        static let photobookBackupFile = photobookDirectory.appending("Photobook.dat")
        static let basketOrderBackupFile = photobookDirectory.appending("BasketOrder.dat")
    }
    
    var basketOrder = Order()
    static var basketOrder: Order { // For convenience
        return shared.basketOrder
    }
    
    static let shared = OrderManager()
    
    func reset() {
        basketOrder = Order()
    }
    
    func submitOrder(_ urls:[String], completionHandler: @escaping (_ error: ErrorMessage?) -> Void) {
    
        Analytics.shared.trackAction(.orderSubmitted, [Analytics.PropertyNames.secondsSinceAppOpen: Analytics.shared.secondsSinceAppOpen(),
                                                       Analytics.PropertyNames.secondsInBackground: Int(Analytics.shared.secondsSpentInBackground)
            ])
        
        //TODO: change to accept two pdf urls
        KiteAPIClient.shared.submitOrder(parameters: basketOrder.orderParameters(), completionHandler: { [weak welf = self] orderId, error in
            welf?.basketOrder.orderId = orderId
            completionHandler(error)
        })
    }
    
    /// Saves the basket order to disk
    func saveBasketOrder() {
        guard let data = try? PropertyListEncoder().encode(OrderManager.basketOrder) else {
            fatalError("OrderManager: encoding of order failed")
        }
        
        if !FileManager.default.fileExists(atPath: OrderManager.Storage.photobookDirectory) {
            do {
                try FileManager.default.createDirectory(atPath: OrderManager.Storage.photobookDirectory, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("OrderManager: could not save order")
            }
        }
        
        let saved = NSKeyedArchiver.archiveRootObject(data, toFile: OrderManager.Storage.basketOrderBackupFile)
        if !saved {
            print("OrderManager: failed to archive order")
        }
    }
    
    /// Loads the basket order from disk and returns it
    func loadBasketOrder() -> Order? {
        guard let unarchivedData = NSKeyedUnarchiver.unarchiveObject(withFile: OrderManager.Storage.basketOrderBackupFile) as? Data else {
            print("ProductManager: failed to unarchive order")
            return nil
        }
        guard let unarchivedOrder = try? PropertyListDecoder().decode(Order.self, from: unarchivedData) else {
            print("ProductManager: decoding of order failed")
            return nil
        }
        
        OrderManager.shared.basketOrder = unarchivedOrder
        return unarchivedOrder
    }
    
}

