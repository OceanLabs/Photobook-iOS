//
//  Template.swift
//  Photobook
//
//  Created by Jaime Landazuri on 16/07/2018.
//  Copyright © 2018 Kite.ly. All rights reserved.
//
import Foundation

@objc public protocol Template {
    var templateId: String { get }
    var name: String { get }
    var availableShippingMethods: [String: [ShippingMethod]]? { get set }
    var countryToRegionMapping: [String: String]? { get set }
}
