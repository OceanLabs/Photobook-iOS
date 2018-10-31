//
//  Modified MIT License
//
//  Copyright (c) 2010-2018 Kite Tech Ltd. https://www.kite.ly
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The software MAY ONLY be used with the Kite Tech Ltd platform and MAY NOT be modified
//  to be used with any competitor platforms. This means the software MAY NOT be modified
//  to place orders with any competitors to Kite Tech Ltd, all orders MUST go through the
//  Kite Tech Ltd platform servers.
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import UIKit

class DeliveryDetails: NSCopying, Codable {
    
    static let savedDetailsKey = "ly.kite.sdk.savedDetailsKey"
    
    static private(set) var savedDeliveryDetails = [DeliveryDetails]()
    
    var firstName: String?
    var lastName: String?
    var email: String?
    var phone: String?
    var line1: String?
    var line2: String?
    var city: String?
    var stateOrCounty: String?
    var zipOrPostcode: String?
    var country = Country.countryForCurrentLocale()
    private(set) var selected = false

    var isValid: Bool {
        get {
            guard let firstName = firstName, !firstName.isEmpty,
                let lastName = lastName, !lastName.isEmpty,
                let email = email, email.isValidEmailAddress(),
                let phone = phone, phone.count >= FormConstants.minPhoneNumberLength,
                let line1 = line1, !line1.isEmpty,
                let city = city, !city.isEmpty,
                let zipOrPostcode = zipOrPostcode, !zipOrPostcode.isEmpty,
                let stateOrCounty = stateOrCounty, !stateOrCounty.isEmpty
                else { return false }
            
            return true
        }
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = DeliveryDetails()
        copy.firstName = firstName
        copy.lastName = lastName
        copy.email = email
        copy.phone = phone
        copy.line1 = line1
        copy.line2 = line2
        copy.city = city
        copy.zipOrPostcode = zipOrPostcode
        copy.stateOrCounty = stateOrCounty
        copy.country = country.copy() as! Country
        copy.selected = selected
        
        return copy
    }
    
    static func loadSavedDetails() {
        guard let deliveryDetailsData = UserDefaults.standard.object(forKey: savedDetailsKey) as? Data,
            let deliveryDetails = try? PropertyListDecoder().decode([DeliveryDetails].self, from: deliveryDetailsData)
        else {
            savedDeliveryDetails = [DeliveryDetails]()
            return
        }
        savedDeliveryDetails = deliveryDetails
    }
    
    static func saveDeliveryDetails() {
        guard let deliveryDetailsData = try? PropertyListEncoder().encode(savedDeliveryDetails) else { return }
        UserDefaults.standard.set(deliveryDetailsData, forKey: savedDetailsKey)
        UserDefaults.standard.synchronize()
    }
    
    static func add(_ deliveryDetails: DeliveryDetails) {
        guard !savedDeliveryDetails.contains(deliveryDetails) else { return }
        savedDeliveryDetails.append(deliveryDetails)
        select(deliveryDetails)
        saveDeliveryDetails()
    }
    
    static func edit(_ deliveryDetails: DeliveryDetails, at index: Int) {
        guard index < savedDeliveryDetails.count else { return }
        savedDeliveryDetails.remove(at: index)
        savedDeliveryDetails.insert(deliveryDetails, at: index)
        saveDeliveryDetails()
    }

    static func remove(_ deliveryDetails: DeliveryDetails) {
        guard let index = savedDeliveryDetails.index(where: { $0 == deliveryDetails }) else { return }
        savedDeliveryDetails.remove(at: index)
        if deliveryDetails.selected, let firstDetails = savedDeliveryDetails.first {
            firstDetails.selected = true
        }
        saveDeliveryDetails()
    }
    
    static func selectedDetails() -> DeliveryDetails? {
        loadSavedDetails()
        return savedDeliveryDetails.first { $0.selected }
    }
    
    static func select(_ deliveryDetails: DeliveryDetails) {
        guard savedDeliveryDetails.contains(deliveryDetails) else { return }
        savedDeliveryDetails.forEach { $0.selected = false }
        deliveryDetails.selected = true
        saveDeliveryDetails()
    }
    
    var fullName: String? {
        guard !(firstName == nil && lastName == nil) else { return nil }
        return String(format: "%@ %@", firstName ?? "", lastName ?? "").trimmingCharacters(in: CharacterSet.whitespaces)
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
    
    func jsonRepresentation() -> [String: String] {
        var json = [String: String]()

        json["recipient_first_name"] = firstName
        json["recipient_last_name"] = lastName
        json["recipient_name"] = fullName
        json["address_line_1"] = line1
        json["address_line_2"] = line2
        json["city"] = city
        json["county_state"] = stateOrCounty
        json["postcode"] = zipOrPostcode
        json["country_code"] = country.codeAlpha3

        return json
    }
}

func ==(lhs: DeliveryDetails, rhs: DeliveryDetails) -> Bool{
    return lhs.firstName == rhs.firstName
        && lhs.lastName == rhs.lastName
        && lhs.email == rhs.email
        && lhs.phone == rhs.phone
        && lhs.line1 == rhs.line1
        && lhs.line2 == rhs.line2
        && lhs.city == rhs.city
        && lhs.stateOrCounty == rhs.stateOrCounty
        && lhs.zipOrPostcode == rhs.zipOrPostcode
        && lhs.country.codeAlpha3 == rhs.country.codeAlpha3
}

extension DeliveryDetails: Hashable {
    
    /// Only the address matters
    var hashValue: Int {
        var stringHash = ""
        if let city = city { stringHash += "ct:\(city.hashValue)," }
        if let zipOrPostcode = zipOrPostcode { stringHash += "zp:\(zipOrPostcode.hashValue)," }
        if let stateOrCounty = stateOrCounty { stringHash += "st:\(stateOrCounty.hashValue)," }
        stringHash += "cy:\(country.name.hashValue),"
        
        return stringHash.hashValue
    }
}

