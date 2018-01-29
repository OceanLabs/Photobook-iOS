//
//  Address.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 05/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
//

import Foundation

let minPhoneNumberLength = 5

enum AddressFieldType: String {
    case firstName
    case lastName
    case line1
    case line2
    case city
    case stateOrCounty
    case zipOrPostcode
    case email
    case phone
}

fileprivate struct Constants {
    static let savedAddressKey = "savedAddressKey"
}

class Address: NSObject, NSCopying, NSSecureCoding {
    static var supportsSecureCoding = true
    
    static let requiredFieldTypes : [AddressFieldType] = [.firstName, .lastName, .line1, .city, .zipOrPostcode, .email, .phone]
    
    var fields = [String : String]()
    lazy var country: Country = Country.countryForCurrentLocale()
    var isValid: Bool {
        get{
            guard let firstName = firstName, let lastName = lastName, !firstName.isEmpty, !lastName.isEmpty else { return false }
            
            guard let line1 = line1, !line1.isEmpty else { return false }
            guard let city = city, !city.isEmpty else { return false }
            guard let zipOrPostcode = zipOrPostcode, !zipOrPostcode.isEmpty else { return false }
            
            guard let email = email, email.isValidEmailAddress() else { return false }
            guard let phone = phone, phone.count >= 5 else { return false }
            
            return true
        }
    }
    
    required convenience init?(coder aDecoder: NSCoder){
        self.init()
        self.fields = aDecoder.decodeObject(forKey: "fields") as! [String : String]
        self.country = aDecoder.decodeObject(forKey: "country") as! Country
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(fields, forKey:"fields")
        aCoder.encode(country, forKey:"country")
    }
    
    func fullName() -> String?{
        guard !(firstName == nil && lastName == nil) else { return nil }
        return String(format: "%@ %@", firstName ?? "", lastName ?? "").trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    func descriptionWithoutRecipient() -> String{
        var s = ""
        
        for part in [line1, line2, city, stateOrCounty, zipOrPostcode, country.name]{
            if let part = part, !part.isEmpty{
                if !s.isEmpty{
                    s = s.appending(", ")
                }
                
                s = s.appending(part)
            }
        }
        
        return s
    }
    
    func jsonRepresentation() -> [String : String]{
        var json = [String : String]()
        
        json["recipient_first_name"] = firstName
        json["recipient_last_name"] = lastName
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
    override var hashValue: Int{
        var stringHash = ""
        if let city = city { stringHash += "ct:\(city.hashValue)," }
        if let zipOrPostcode = zipOrPostcode { stringHash += "zp:\(zipOrPostcode.hashValue)," }
        if let stateOrCounty = stateOrCounty { stringHash += "st:\(stateOrCounty.hashValue)," }
        stringHash += "cy:\(country.name.hashValue),"
        
        return stringHash.hashValue
    }
    
    func copy(with zone: NSZone? = nil) -> Any{
        let copy = Address()
        copy.firstName = firstName
        copy.lastName = lastName
        copy.line1 = line1
        copy.line2 = line2
        copy.city = city
        copy.zipOrPostcode = zipOrPostcode
        copy.stateOrCounty = stateOrCounty
        copy.country = country.copy() as! Country
        copy.email = email
        copy.phone = phone
        
        return copy
    }
    
    func saveAddressAsLatest(){
        guard let address = ProductManager.shared.address else { return }
        let addressData = NSKeyedArchiver.archivedData(withRootObject: address)
        UserDefaults.standard.set(addressData, forKey: Constants.savedAddressKey)
        UserDefaults.standard.synchronize()
    }
    
    static func loadLatestAddress() -> Address?{
        guard let addressData = UserDefaults.standard.object(forKey: Constants.savedAddressKey) as? Data else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: addressData) as? Address
    }
}

func ==(lhs: Address, rhs: Address) -> Bool{
    return lhs.firstName == rhs.firstName
        && lhs.lastName == rhs.lastName
        && lhs.line1 == rhs.line1
        && lhs.line2 == rhs.line2
        && lhs.city == rhs.city
        && lhs.stateOrCounty == rhs.stateOrCounty
        && lhs.zipOrPostcode == rhs.zipOrPostcode
        && lhs.country.codeAlpha3 == rhs.country.codeAlpha3
        && lhs.email == rhs.email
        && lhs.phone == rhs.phone
}

    // MARK: - Convenience getters and setters

extension Address{
    var firstName: String? {
        get{
            return fields[AddressFieldType.firstName.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.firstName.rawValue] = newValue
        }
    }
    var lastName: String? {
        get{
            return fields[AddressFieldType.lastName.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.lastName.rawValue] = newValue
        }
    }
    var line1: String? {
        get{
            return fields[AddressFieldType.line1.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.line1.rawValue] = newValue
        }
    }
    var line2: String? {
        get{
            return fields[AddressFieldType.line2.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.line2.rawValue] = newValue
        }
    }
    var city: String? {
        get{
            return fields[AddressFieldType.city.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.city.rawValue] = newValue
        }
    }
    var stateOrCounty: String? {
        get{
            return fields[AddressFieldType.stateOrCounty.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.stateOrCounty.rawValue] = newValue
        }
    }
    var zipOrPostcode: String? {
        get{
            return fields[AddressFieldType.zipOrPostcode.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.zipOrPostcode.rawValue] = newValue
        }
    }
    var email: String? {
        get{
            return fields[AddressFieldType.email.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.email.rawValue] = newValue
        }
    }
    var phone: String? {
        get{
            return fields[AddressFieldType.phone.rawValue]
        }
        set(newValue){
            fields[AddressFieldType.phone.rawValue] = newValue
        }
    }
}
