//
//  Address.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 05/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

enum AddressFieldType: String {
    case line1
    case line2
    case city
    case stateOrCounty
    case zipOrPostcode
}

class Address: NSCopying, Codable, Hashable {
    
    var line1: String?
    var line2: String?
    var city: String?
    var stateOrCounty: String?
    var zipOrPostcode: String?
    var country: Country
    
    static var savedAddresses = Address.loadSavedAddresses()
    
    private struct Constants {
        static let savedAddressesKey = "ly.kite.sdk.savedAddressesKey"
    }
    
    init() {
         country = Country.countryForCurrentLocale()
    }
    
    var isValid: Bool {
        get{            
            guard let line1 = line1, !line1.isEmpty else { return false }
            guard let city = city, !city.isEmpty else { return false }
            guard let zipOrPostcode = zipOrPostcode, !zipOrPostcode.isEmpty else { return false }
            
            return true
        }
    }
    
    func descriptionWithoutLine1() -> String {
        var s = ""
        
        for part in [line2, city, stateOrCounty, zipOrPostcode, country.name]{
            if let part = part, !part.isEmpty{
                if !s.isEmpty{
                    s = s.appending(", ")
                }
                
                s = s.appending(part)
            }
        }
        
        return s
    }
    
    func jsonRepresentation() -> [String : String] {
        var json = [String : String]()
        
        json["address_line_1"] = line1
        json["address_line_2"] = line2
        json["city"] = city
        json["county_state"] = stateOrCounty
        json["postcode"] = zipOrPostcode
        json["country_code"] = country.codeAlpha3
        
        return json
    }
    
    
    /// Only calculate hash value with fields that could matter in the delivery costs, 
    /// i.e. the fields that if changed necessitate a delivery cost recalc
    var hashValue: Int {
        var stringHash = ""
        if let city = city { stringHash += "ct:\(city.hashValue)," }
        if let zipOrPostcode = zipOrPostcode { stringHash += "zp:\(zipOrPostcode.hashValue)," }
        if let stateOrCounty = stateOrCounty { stringHash += "st:\(stateOrCounty.hashValue)," }
        stringHash += "cy:\(country.name.hashValue),"
        
        return stringHash.hashValue
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = Address()
        copy.line1 = line1
        copy.line2 = line2
        copy.city = city
        copy.zipOrPostcode = zipOrPostcode
        copy.stateOrCounty = stateOrCounty
        copy.country = country.copy() as! Country
        
        return copy
    }
    
}

func ==(lhs: Address, rhs: Address) -> Bool {
    return lhs.line1 == rhs.line1
        && lhs.line2 == rhs.line2
        && lhs.city == rhs.city
        && lhs.stateOrCounty == rhs.stateOrCounty
        && lhs.zipOrPostcode == rhs.zipOrPostcode
        && lhs.country.codeAlpha3 == rhs.country.codeAlpha3
}

extension Address {
    // MARK: - Saved Addresses
    
    func addToSavedAddresses() {
        Address.savedAddresses.append(self)
        Address.saveAddresses()
    }
    
    func removeFromSavedAddresses() {
        if let index = Address.savedAddresses.index(where: { $0 == self }) {
            Address.savedAddresses.remove(at: index)
            Address.saveAddresses()
        }
    }
    
    private static func loadSavedAddresses() -> [Address] {
        guard let addressesData = UserDefaults.standard.object(forKey: Constants.savedAddressesKey) as? Data,
        let addresses = try? PropertyListDecoder().decode([Address].self, from: addressesData)
            else { return [Address]() }
        return addresses
    }
    
    static func saveAddresses() {
        
        let addressesData = try? PropertyListEncoder().encode(savedAddresses)
        UserDefaults.standard.set(addressesData, forKey: Constants.savedAddressesKey)
        UserDefaults.standard.synchronize()
    }
    
}
