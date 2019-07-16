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

/// Delivery details information to be used at checkout
@objc public class OLDeliveryDetails: NSObject, NSCopying, Codable {
    
    static let savedDetailsKey = "ly.kite.sdk.savedDetailsKey"
    
    static private(set) var savedDeliveryDetails = [OLDeliveryDetails]()
    
    @objc internal(set) public var firstName: String?
    @objc internal(set) public var lastName: String?
    @objc internal(set) public var email: String?
    @objc internal(set) public var phone: String?
    @objc internal(set) public var line1: String?
    @objc internal(set) public var line2: String?
    @objc internal(set) public var city: String?
    @objc internal(set) public var stateOrCounty: String?
    @objc internal(set) public var zipOrPostcode: String?
    
    /// 3-letter country code
    @objc public var countryCode: String { return country.codeAlpha3 }
    
    var country = Country.countryForCurrentLocale()
    private(set) var selected = false
    
    
    override init() {
        // Overriden to make initialiser internal
    }
    
    /// Initializer
    ///
    /// - Note: The initializer will fail if a valid email is not provided or the phone number is less than 5 characters long
    ///
    /// - Parameters:
    ///   - firstName: The firstname of the recipient
    ///   - lastName: The lastname of the recipient
    ///   - email: A valid contact email
    ///   - phone: A contact phone
    ///   - line1: First line of the recipient's address
    ///   - line2: Second line of the recipient's address, if needed
    ///   - city: City of the recipient's address
    ///   - stateOrCounty: State or county of the recipient's address
    ///   - zipOrPostcode: ZIP code or postcode of the recipient's address
    ///   - countryCode: 2 or 3 letter code as listed by ISO / UN
    @objc public convenience init?(firstName: String, lastName: String,
                email: String, phone: String,
                line1: String, line2: String?,
                city: String, stateOrCounty: String,
                zipOrPostcode: String, countryCode: String) {
        
        guard let country = Country.countryFor(code: countryCode) else { return nil }
        
        self.init()
        
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.phone = phone
        self.line1 = line1
        self.line2 = line2
        self.city = city
        self.stateOrCounty = stateOrCounty
        self.zipOrPostcode = zipOrPostcode
        self.country = country
        
        if !self.isValid { return nil }
    }
    
    var isValid: Bool {
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
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = OLDeliveryDetails()
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
            let deliveryDetails = try? PropertyListDecoder().decode([OLDeliveryDetails].self, from: deliveryDetailsData)
            else {
                savedDeliveryDetails = [OLDeliveryDetails]()
                return
        }
        savedDeliveryDetails = deliveryDetails
    }
    
    static func saveDeliveryDetails() {
        guard let deliveryDetailsData = try? PropertyListEncoder().encode(savedDeliveryDetails) else { return }
        UserDefaults.standard.set(deliveryDetailsData, forKey: savedDetailsKey)
        UserDefaults.standard.synchronize()
    }
    
    static func add(_ deliveryDetails: OLDeliveryDetails) {
        guard !savedDeliveryDetails.contains(deliveryDetails) else { return }
        savedDeliveryDetails.append(deliveryDetails)
        select(deliveryDetails)
        saveDeliveryDetails()
    }
    
    static func edit(_ deliveryDetails: OLDeliveryDetails, at index: Int) {
        guard index < savedDeliveryDetails.count else { return }
        savedDeliveryDetails.remove(at: index)
        savedDeliveryDetails.insert(deliveryDetails, at: index)
        saveDeliveryDetails()
    }
    
    static func remove(_ deliveryDetails: OLDeliveryDetails) {
        guard let index = savedDeliveryDetails.firstIndex(where: { $0 == deliveryDetails }) else { return }
        savedDeliveryDetails.remove(at: index)
        if deliveryDetails.selected, let firstDetails = savedDeliveryDetails.first {
            firstDetails.selected = true
        }
        saveDeliveryDetails()
    }
    
    static func selectedDetails() -> OLDeliveryDetails? {
        loadSavedDetails()
        return savedDeliveryDetails.first { $0.selected }
    }
    
    static func select(_ deliveryDetails: OLDeliveryDetails) {
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
        
        json["recipient_name"] = fullName
        json["address_line_1"] = line1
        json["address_line_2"] = line2
        json["city"] = city
        json["county_state"] = stateOrCounty
        json["postcode"] = zipOrPostcode
        json["country_code"] = country.codeAlpha3
        
        return json
    }
    
    /// Only the address matters
    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(city)
        hasher.combine(zipOrPostcode)
        hasher.combine(stateOrCounty)
        hasher.combine(country.name)
        return hasher.finalize()
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? OLDeliveryDetails else { return false }
        return firstName == other.firstName
            && lastName == other.lastName
            && email == other.email
            && phone == other.phone
            && line1 == other.line1
            && line2 == other.line2
            && city == other.city
            && stateOrCounty == other.stateOrCounty
            && zipOrPostcode == other.zipOrPostcode
            && country.codeAlpha3 == other.country.codeAlpha3
    }
}
