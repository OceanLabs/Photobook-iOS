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

import Foundation

class Country: NSCopying, Codable {
    
    let name: String
    let codeAlpha2: String
    let codeAlpha3: String
    let currencyCode: String
    
    init(name: String, codeAlpha2: String, codeAlpha3: String, currencyCode: String) {
        self.name = name
        self.codeAlpha2 = codeAlpha2
        self.codeAlpha3 = codeAlpha3
        self.currencyCode = currencyCode
    }
    
    class func countryForCurrentLocale() -> Country {
        if let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String,
            let country = Country.countryFor(code: countryCode){
            return country
        }
        
        // fallback to GB
        return Country.countryFor(code: "GBR")!
    }
    
    class func countryFor(name: String) -> Country? {
        for country in self.countries {
            if country.name == name {
                return country
            }
        }
        
        return nil
    }
    
    class func countryFor(code: String) -> Country? {
        for country in self.countries{
            if country.codeAlpha3 == code || country.codeAlpha2 == code{
                return country
            }
        }
        
        return nil
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        return Country(name: self.name, codeAlpha2: self.codeAlpha2, codeAlpha3: self.codeAlpha3, currencyCode: self.currencyCode)
    }
    
    class var countries: [Country] {
        get {
            var countries: [Country] = [Country]()
            
            countries.append(Country(name: "Åland Islands", codeAlpha2: "AX", codeAlpha3: "ALA", currencyCode: "EUR"))
            countries.append(Country(name: "Afghanistan", codeAlpha2: "AF", codeAlpha3: "AFG", currencyCode: "AFN"))
            countries.append(Country(name: "Albania", codeAlpha2: "AL", codeAlpha3: "ALB", currencyCode: "ALL"))
            countries.append(Country(name: "Algeria", codeAlpha2: "DZ", codeAlpha3: "DZA", currencyCode: "DZD"))
            countries.append(Country(name: "American Samoa", codeAlpha2: "AS", codeAlpha3: "ASM", currencyCode: "USD"))
            countries.append(Country(name: "Andorra", codeAlpha2: "AD", codeAlpha3: "AND", currencyCode: "EUR"))
            countries.append(Country(name: "Angola", codeAlpha2: "AO", codeAlpha3: "AGO", currencyCode: "AOA"))
            countries.append(Country(name: "Anguilla", codeAlpha2: "AI", codeAlpha3: "AIA", currencyCode: "XCD"))
            countries.append(Country(name: "Antarctica", codeAlpha2: "AQ", codeAlpha3: "ATA", currencyCode: ""))
            countries.append(Country(name: "Antigua and Barbuda", codeAlpha2: "AG", codeAlpha3: "ATG", currencyCode: "XCD"))
            countries.append(Country(name: "Argentina", codeAlpha2: "AR", codeAlpha3: "ARG", currencyCode: "ARS"))
            countries.append(Country(name: "Armenia", codeAlpha2: "AM", codeAlpha3: "ARM", currencyCode: "AMD"))
            countries.append(Country(name: "Aruba", codeAlpha2: "AW", codeAlpha3: "ABW", currencyCode: "AWG"))
            countries.append(Country(name: "Australia", codeAlpha2: "AU", codeAlpha3: "AUS", currencyCode: "AUD"))
            countries.append(Country(name: "Austria", codeAlpha2: "AT", codeAlpha3: "AUT", currencyCode: "EUR"))
            countries.append(Country(name: "Azerbaijan", codeAlpha2: "AZ", codeAlpha3: "AZE", currencyCode: "AZN"))
            countries.append(Country(name: "Bahamas", codeAlpha2: "BS", codeAlpha3: "BHS", currencyCode: "BSD"))
            countries.append(Country(name: "Bahrain", codeAlpha2: "BH", codeAlpha3: "BHR", currencyCode: "BHD"))
            countries.append(Country(name: "Bangladesh", codeAlpha2: "BD", codeAlpha3: "BGD", currencyCode: "BDT"))
            countries.append(Country(name: "Barbados", codeAlpha2: "BB", codeAlpha3: "BRB", currencyCode: "BBD"))
            countries.append(Country(name: "Belarus", codeAlpha2: "BY", codeAlpha3: "BLR", currencyCode: "BYR"))
            countries.append(Country(name: "Belgium", codeAlpha2: "BE", codeAlpha3: "BEL", currencyCode: "EUR"))
            countries.append(Country(name: "Belize", codeAlpha2: "BZ", codeAlpha3: "BLZ", currencyCode: "BZD"))
            countries.append(Country(name: "Benin", codeAlpha2: "BJ", codeAlpha3: "BEN", currencyCode: "XOF"))
            countries.append(Country(name: "Bermuda", codeAlpha2: "BM", codeAlpha3: "BMU", currencyCode: "BMD"))
            countries.append(Country(name: "Bhutan", codeAlpha2: "BT", codeAlpha3: "BTN", currencyCode: "INR"))
            countries.append(Country(name: "Bolivia, Plurinational State of", codeAlpha2: "BO", codeAlpha3: "BOL", currencyCode: "BOB"))
            countries.append(Country(name: "Bonaire, Sint Eustatius and Saba", codeAlpha2: "BQ", codeAlpha3: "BES", currencyCode: "USD"))
            countries.append(Country(name: "Bosnia and Herzegovina", codeAlpha2: "BA", codeAlpha3: "BIH", currencyCode: "BAM"))
            countries.append(Country(name: "Botswana", codeAlpha2: "BW", codeAlpha3: "BWA", currencyCode: "BWP"))
            countries.append(Country(name: "Bouvet Island", codeAlpha2: "BV", codeAlpha3: "BVT", currencyCode: "NOK"))
            countries.append(Country(name: "Brazil", codeAlpha2: "BR", codeAlpha3: "BRA", currencyCode: "BRL"))
            countries.append(Country(name: "British Indian Ocean Territory", codeAlpha2: "IO", codeAlpha3: "IOT", currencyCode: "USD"))
            countries.append(Country(name: "Brunei Darussalam", codeAlpha2: "BN", codeAlpha3: "BRN", currencyCode: "BND"))
            countries.append(Country(name: "Bulgaria", codeAlpha2: "BG", codeAlpha3: "BGR", currencyCode: "BGN"))
            countries.append(Country(name: "Burkina Faso", codeAlpha2: "BF", codeAlpha3: "BFA", currencyCode: "XOF"))
            countries.append(Country(name: "Burundi", codeAlpha2: "BI", codeAlpha3: "BDI", currencyCode: "BIF"))
            countries.append(Country(name: "Cambodia", codeAlpha2: "KH", codeAlpha3: "KHM", currencyCode: "KHR"))
            countries.append(Country(name: "Cameroon", codeAlpha2: "CM", codeAlpha3: "CMR", currencyCode: "XAF"))
            countries.append(Country(name: "Canada", codeAlpha2: "CA", codeAlpha3: "CAN", currencyCode: "CAD"))
            countries.append(Country(name: "Cape Verde", codeAlpha2: "CV", codeAlpha3: "CPV", currencyCode: "CVE"))
            countries.append(Country(name: "Cayman Islands", codeAlpha2: "KY", codeAlpha3: "CYM", currencyCode: "KYD"))
            countries.append(Country(name: "Central African Republic", codeAlpha2: "CF", codeAlpha3: "CAF", currencyCode: "XAF"))
            countries.append(Country(name: "Chad", codeAlpha2: "TD", codeAlpha3: "TCD", currencyCode: "XAF"))
            countries.append(Country(name: "Chile", codeAlpha2: "CL", codeAlpha3: "CHL", currencyCode: "CLP"))
            countries.append(Country(name: "China", codeAlpha2: "CN", codeAlpha3: "CHN", currencyCode: "CNY"))
            countries.append(Country(name: "Christmas Island", codeAlpha2: "CX", codeAlpha3: "CXR", currencyCode: "AUD"))
            countries.append(Country(name: "Cocos (Keeling) Islands", codeAlpha2: "CC", codeAlpha3: "CCK", currencyCode: "AUD"))
            countries.append(Country(name: "Colombia", codeAlpha2: "CO", codeAlpha3: "COL", currencyCode: "COP"))
            countries.append(Country(name: "Comoros", codeAlpha2: "KM", codeAlpha3: "COM", currencyCode: "KMF"))
            countries.append(Country(name: "Congo", codeAlpha2: "CG", codeAlpha3: "COG", currencyCode: "XAF"))
            countries.append(Country(name: "Congo, the Democratic Republic of the", codeAlpha2: "CD", codeAlpha3: "COD", currencyCode: "CDF"))
            countries.append(Country(name: "Cook Islands", codeAlpha2: "CK", codeAlpha3: "COK", currencyCode: "NZD"))
            countries.append(Country(name: "Costa Rica", codeAlpha2: "CR", codeAlpha3: "CRI", currencyCode: "CRC"))
            countries.append(Country(name: "Croatia", codeAlpha2: "HR", codeAlpha3: "HRV", currencyCode: "HRK"))
            countries.append(Country(name: "Cuba", codeAlpha2: "CU", codeAlpha3: "CUB", currencyCode: "CUP"))
            countries.append(Country(name: "Curaçao", codeAlpha2: "CW", codeAlpha3: "CUW", currencyCode: "ANG"))
            countries.append(Country(name: "Cyprus", codeAlpha2: "CY", codeAlpha3: "CYP", currencyCode: "EUR"))
            countries.append(Country(name: "Czech Republic", codeAlpha2: "CZ", codeAlpha3: "CZE", currencyCode: "CZK"))
            countries.append(Country(name: "Côte d'Ivoire", codeAlpha2: "CI", codeAlpha3: "CIV", currencyCode: "XOF"))
            countries.append(Country(name: "Denmark", codeAlpha2: "DK", codeAlpha3: "DNK", currencyCode: "DKK"))
            countries.append(Country(name: "Djibouti", codeAlpha2: "DJ", codeAlpha3: "DJI", currencyCode: "DJF"))
            countries.append(Country(name: "Dominica", codeAlpha2: "DM", codeAlpha3: "DMA", currencyCode: "XCD"))
            countries.append(Country(name: "Dominican Republic", codeAlpha2: "DO", codeAlpha3: "DOM", currencyCode: "DOP"))
            countries.append(Country(name: "Ecuador", codeAlpha2: "EC", codeAlpha3: "ECU", currencyCode: "USD"))
            countries.append(Country(name: "Egypt", codeAlpha2: "EG", codeAlpha3: "EGY", currencyCode: "EGP"))
            countries.append(Country(name: "El Salvador", codeAlpha2: "SV", codeAlpha3: "SLV", currencyCode: "USD"))
            countries.append(Country(name: "Equatorial Guinea", codeAlpha2: "GQ", codeAlpha3: "GNQ", currencyCode: "XAF"))
            countries.append(Country(name: "Eritrea", codeAlpha2: "ER", codeAlpha3: "ERI", currencyCode: "ERN"))
            countries.append(Country(name: "Estonia", codeAlpha2: "EE", codeAlpha3: "EST", currencyCode: "EUR"))
            countries.append(Country(name: "Ethiopia", codeAlpha2: "ET", codeAlpha3: "ETH", currencyCode: "ETB"))
            countries.append(Country(name: "Falkland Islands (Malvinas)", codeAlpha2: "FK", codeAlpha3: "FLK", currencyCode: "FKP"))
            countries.append(Country(name: "Faroe Islands", codeAlpha2: "FO", codeAlpha3: "FRO", currencyCode: "DKK"))
            countries.append(Country(name: "Fiji", codeAlpha2: "FJ", codeAlpha3: "FJI", currencyCode: "FJD"))
            countries.append(Country(name: "Finland", codeAlpha2: "FI", codeAlpha3: "FIN", currencyCode: "EUR"))
            countries.append(Country(name: "France", codeAlpha2: "FR", codeAlpha3: "FRA", currencyCode: "EUR"))
            countries.append(Country(name: "French Guiana", codeAlpha2: "GF", codeAlpha3: "GUF", currencyCode: "EUR"))
            countries.append(Country(name: "French Polynesia", codeAlpha2: "PF", codeAlpha3: "PYF", currencyCode: "XPF"))
            countries.append(Country(name: "French Southern Territories", codeAlpha2: "TF", codeAlpha3: "ATF", currencyCode: "EUR"))
            countries.append(Country(name: "Gabon", codeAlpha2: "GA", codeAlpha3: "GAB", currencyCode: "XAF"))
            countries.append(Country(name: "Gambia", codeAlpha2: "GM", codeAlpha3: "GMB", currencyCode: "GMD"))
            countries.append(Country(name: "Georgia", codeAlpha2: "GE", codeAlpha3: "GEO", currencyCode: "GEL"))
            countries.append(Country(name: "Germany", codeAlpha2: "DE", codeAlpha3: "DEU", currencyCode: "EUR"))
            countries.append(Country(name: "Ghana", codeAlpha2: "GH", codeAlpha3: "GHA", currencyCode: "GHS"))
            countries.append(Country(name: "Gibraltar", codeAlpha2: "GI", codeAlpha3: "GIB", currencyCode: "GIP"))
            countries.append(Country(name: "Greece", codeAlpha2: "GR", codeAlpha3: "GRC", currencyCode: "EUR"))
            countries.append(Country(name: "Greenland", codeAlpha2: "GL", codeAlpha3: "GRL", currencyCode: "DKK"))
            countries.append(Country(name: "Grenada", codeAlpha2: "GD", codeAlpha3: "GRD", currencyCode: "XCD"))
            countries.append(Country(name: "Guadeloupe", codeAlpha2: "GP", codeAlpha3: "GLP", currencyCode: "EUR"))
            countries.append(Country(name: "Guam", codeAlpha2: "GU", codeAlpha3: "GUM", currencyCode: "USD"))
            countries.append(Country(name: "Guatemala", codeAlpha2: "GT", codeAlpha3: "GTM", currencyCode: "GTQ"))
            countries.append(Country(name: "Guernsey", codeAlpha2: "GG", codeAlpha3: "GGY", currencyCode: "GBP"))
            countries.append(Country(name: "Guinea", codeAlpha2: "GN", codeAlpha3: "GIN", currencyCode: "GNF"))
            countries.append(Country(name: "Guinea-Bissau", codeAlpha2: "GW", codeAlpha3: "GNB", currencyCode: "XOF"))
            countries.append(Country(name: "Guyana", codeAlpha2: "GY", codeAlpha3: "GUY", currencyCode: "GYD"))
            countries.append(Country(name: "Haiti", codeAlpha2: "HT", codeAlpha3: "HTI", currencyCode: "USD"))
            countries.append(Country(name: "Heard Island and McDonald Mcdonald Islands", codeAlpha2: "HM", codeAlpha3: "HMD", currencyCode: "AUD"))
            countries.append(Country(name: "Holy See (Vatican City State)", codeAlpha2: "VA", codeAlpha3: "VAT", currencyCode: "EUR"))
            countries.append(Country(name: "Honduras", codeAlpha2: "HN", codeAlpha3: "HND", currencyCode: "HNL"))
            countries.append(Country(name: "Hong Kong", codeAlpha2: "HK", codeAlpha3: "HKG", currencyCode: "HKD"))
            countries.append(Country(name: "Hungary", codeAlpha2: "HU", codeAlpha3: "HUN", currencyCode: "HUF"))
            countries.append(Country(name: "Iceland", codeAlpha2: "IS", codeAlpha3: "ISL", currencyCode: "ISK"))
            countries.append(Country(name: "India", codeAlpha2: "IN", codeAlpha3: "IND", currencyCode: "INR"))
            countries.append(Country(name: "Indonesia", codeAlpha2: "ID", codeAlpha3: "IDN", currencyCode: "IDR"))
            countries.append(Country(name: "Iran, Islamic Republic of", codeAlpha2: "IR", codeAlpha3: "IRN", currencyCode: "IRR"))
            countries.append(Country(name: "Iraq", codeAlpha2: "IQ", codeAlpha3: "IRQ", currencyCode: "IQD"))
            countries.append(Country(name: "Ireland", codeAlpha2: "IE", codeAlpha3: "IRL", currencyCode: "EUR"))
            countries.append(Country(name: "Isle of Man", codeAlpha2: "IM", codeAlpha3: "IMN", currencyCode: "GBP"))
            countries.append(Country(name: "Israel", codeAlpha2: "IL", codeAlpha3: "ISR", currencyCode: "ILS"))
            countries.append(Country(name: "Italy", codeAlpha2: "IT", codeAlpha3: "ITA", currencyCode: "EUR"))
            countries.append(Country(name: "Jamaica", codeAlpha2: "JM", codeAlpha3: "JAM", currencyCode: "JMD"))
            countries.append(Country(name: "Japan", codeAlpha2: "JP", codeAlpha3: "JPN", currencyCode: "JPY"))
            countries.append(Country(name: "Jersey", codeAlpha2: "JE", codeAlpha3: "JEY", currencyCode: "GBP"))
            countries.append(Country(name: "Jordan", codeAlpha2: "JO", codeAlpha3: "JOR", currencyCode: "JOD"))
            countries.append(Country(name: "Kazakhstan", codeAlpha2: "KZ", codeAlpha3: "KAZ", currencyCode: "KZT"))
            countries.append(Country(name: "Kenya", codeAlpha2: "KE", codeAlpha3: "KEN", currencyCode: "KES"))
            countries.append(Country(name: "Kiribati", codeAlpha2: "KI", codeAlpha3: "KIR", currencyCode: "AUD"))
            countries.append(Country(name: "Korea, Democratic People's Republic of", codeAlpha2: "KP", codeAlpha3: "PRK", currencyCode: "KPW"))
            countries.append(Country(name: "Korea, Republic of", codeAlpha2: "KR", codeAlpha3: "KOR", currencyCode: "KRW"))
            countries.append(Country(name: "Kuwait", codeAlpha2: "KW", codeAlpha3: "KWT", currencyCode: "KWD"))
            countries.append(Country(name: "Kyrgyzstan", codeAlpha2: "KG", codeAlpha3: "KGZ", currencyCode: "KGS"))
            countries.append(Country(name: "Lao People's Democratic Republic", codeAlpha2: "LA", codeAlpha3: "LAO", currencyCode: "LAK"))
            countries.append(Country(name: "Latvia", codeAlpha2: "LV", codeAlpha3: "LVA", currencyCode: "LVL"))
            countries.append(Country(name: "Lebanon", codeAlpha2: "LB", codeAlpha3: "LBN", currencyCode: "LBP"))
            countries.append(Country(name: "Lesotho", codeAlpha2: "LS", codeAlpha3: "LSO", currencyCode: "ZAR"))
            countries.append(Country(name: "Liberia", codeAlpha2: "LR", codeAlpha3: "LBR", currencyCode: "LRD"))
            countries.append(Country(name: "Libya", codeAlpha2: "LY", codeAlpha3: "LBY", currencyCode: "LYD"))
            countries.append(Country(name: "Liechtenstein", codeAlpha2: "LI", codeAlpha3: "LIE", currencyCode: "CHF"))
            countries.append(Country(name: "Lithuania", codeAlpha2: "LT", codeAlpha3: "LTU", currencyCode: "LTL"))
            countries.append(Country(name: "Luxembourg", codeAlpha2: "LU", codeAlpha3: "LUX", currencyCode: "EUR"))
            countries.append(Country(name: "Macao", codeAlpha2: "MO", codeAlpha3: "MAC", currencyCode: "MOP"))
            countries.append(Country(name: "Macedonia, the Former Yugoslav Republic of", codeAlpha2: "MK", codeAlpha3: "MKD", currencyCode: "MKD"))
            countries.append(Country(name: "Madagascar", codeAlpha2: "MG", codeAlpha3: "MDG", currencyCode: "MGA"))
            countries.append(Country(name: "Malawi", codeAlpha2: "MW", codeAlpha3: "MWI", currencyCode: "MWK"))
            countries.append(Country(name: "Malaysia", codeAlpha2: "MY", codeAlpha3: "MYS", currencyCode: "MYR"))
            countries.append(Country(name: "Maldives", codeAlpha2: "MV", codeAlpha3: "MDV", currencyCode: "MVR"))
            countries.append(Country(name: "Mali", codeAlpha2: "ML", codeAlpha3: "MLI", currencyCode: "XOF"))
            countries.append(Country(name: "Malta", codeAlpha2: "MT", codeAlpha3: "MLT", currencyCode: "EUR"))
            countries.append(Country(name: "Marshall Islands", codeAlpha2: "MH", codeAlpha3: "MHL", currencyCode: "USD"))
            countries.append(Country(name: "Martinique", codeAlpha2: "MQ", codeAlpha3: "MTQ", currencyCode: "EUR"))
            countries.append(Country(name: "Mauritania", codeAlpha2: "MR", codeAlpha3: "MRT", currencyCode: "MRO"))
            countries.append(Country(name: "Mauritius", codeAlpha2: "MU", codeAlpha3: "MUS", currencyCode: "MUR"))
            countries.append(Country(name: "Mayotte", codeAlpha2: "YT", codeAlpha3: "MYT", currencyCode: "EUR"))
            countries.append(Country(name: "Mexico", codeAlpha2: "MX", codeAlpha3: "MEX", currencyCode: "MXN"))
            countries.append(Country(name: "Micronesia, Federated States of", codeAlpha2: "FM", codeAlpha3: "FSM", currencyCode: "USD"))
            countries.append(Country(name: "Moldova, Republic of", codeAlpha2: "MD", codeAlpha3: "MDA", currencyCode: "MDL"))
            countries.append(Country(name: "Monaco", codeAlpha2: "MC", codeAlpha3: "MCO", currencyCode: "EUR"))
            countries.append(Country(name: "Mongolia", codeAlpha2: "MN", codeAlpha3: "MNG", currencyCode: "MNT"))
            countries.append(Country(name: "Montenegro", codeAlpha2: "ME", codeAlpha3: "MNE", currencyCode: "EUR"))
            countries.append(Country(name: "Montserrat", codeAlpha2: "MS", codeAlpha3: "MSR", currencyCode: "XCD"))
            countries.append(Country(name: "Morocco", codeAlpha2: "MA", codeAlpha3: "MAR", currencyCode: "MAD"))
            countries.append(Country(name: "Mozambique", codeAlpha2: "MZ", codeAlpha3: "MOZ", currencyCode: "MZN"))
            countries.append(Country(name: "Myanmar", codeAlpha2: "MM", codeAlpha3: "MMR", currencyCode: "MMK"))
            countries.append(Country(name: "Namibia", codeAlpha2: "NA", codeAlpha3: "NAM", currencyCode: "ZAR"))
            countries.append(Country(name: "Nauru", codeAlpha2: "NR", codeAlpha3: "NRU", currencyCode: "AUD"))
            countries.append(Country(name: "Nepal", codeAlpha2: "NP", codeAlpha3: "NPL", currencyCode: "NPR"))
            countries.append(Country(name: "Netherlands", codeAlpha2: "NL", codeAlpha3: "NLD", currencyCode: "EUR"))
            countries.append(Country(name: "New Caledonia", codeAlpha2: "NC", codeAlpha3: "NCL", currencyCode: "XPF"))
            countries.append(Country(name: "New Zealand", codeAlpha2: "NZ", codeAlpha3: "NZL", currencyCode: "NZD"))
            countries.append(Country(name: "Nicaragua", codeAlpha2: "NI", codeAlpha3: "NIC", currencyCode: "NIO"))
            countries.append(Country(name: "Niger", codeAlpha2: "NE", codeAlpha3: "NER", currencyCode: "XOF"))
            countries.append(Country(name: "Nigeria", codeAlpha2: "NG", codeAlpha3: "NGA", currencyCode: "NGN"))
            countries.append(Country(name: "Niue", codeAlpha2: "NU", codeAlpha3: "NIU", currencyCode: "NZD"))
            countries.append(Country(name: "Norfolk Island", codeAlpha2: "NF", codeAlpha3: "NFK", currencyCode: "AUD"))
            countries.append(Country(name: "Northern Mariana Islands", codeAlpha2: "MP", codeAlpha3: "MNP", currencyCode: "USD"))
            countries.append(Country(name: "Norway", codeAlpha2: "NO", codeAlpha3: "NOR", currencyCode: "NOK"))
            countries.append(Country(name: "Oman", codeAlpha2: "OM", codeAlpha3: "OMN", currencyCode: "OMR"))
            countries.append(Country(name: "Pakistan", codeAlpha2: "PK", codeAlpha3: "PAK", currencyCode: "PKR"))
            countries.append(Country(name: "Palau", codeAlpha2: "PW", codeAlpha3: "PLW", currencyCode: "USD"))
            countries.append(Country(name: "Palestine, State of", codeAlpha2: "PS", codeAlpha3: "PSE", currencyCode: ""))
            countries.append(Country(name: "Panama", codeAlpha2: "PA", codeAlpha3: "PAN", currencyCode: "USD"))
            countries.append(Country(name: "Papua New Guinea", codeAlpha2: "PG", codeAlpha3: "PNG", currencyCode: "PGK"))
            countries.append(Country(name: "Paraguay", codeAlpha2: "PY", codeAlpha3: "PRY", currencyCode: "PYG"))
            countries.append(Country(name: "Peru", codeAlpha2: "PE", codeAlpha3: "PER", currencyCode: "PEN"))
            countries.append(Country(name: "Philippines", codeAlpha2: "PH", codeAlpha3: "PHL", currencyCode: "PHP"))
            countries.append(Country(name: "Pitcairn", codeAlpha2: "PN", codeAlpha3: "PCN", currencyCode: "NZD"))
            countries.append(Country(name: "Poland", codeAlpha2: "PL", codeAlpha3: "POL", currencyCode: "PLN"))
            countries.append(Country(name: "Portugal", codeAlpha2: "PT", codeAlpha3: "PRT", currencyCode: "EUR"))
            countries.append(Country(name: "Puerto Rico", codeAlpha2: "PR", codeAlpha3: "PRI", currencyCode: "USD"))
            countries.append(Country(name: "Qatar", codeAlpha2: "QA", codeAlpha3: "QAT", currencyCode: "QAR"))
            countries.append(Country(name: "Romania", codeAlpha2: "RO", codeAlpha3: "ROU", currencyCode: "RON"))
            countries.append(Country(name: "Russian Federation", codeAlpha2: "RU", codeAlpha3: "RUS", currencyCode: "RUB"))
            countries.append(Country(name: "Rwanda", codeAlpha2: "RW", codeAlpha3: "RWA", currencyCode: "RWF"))
            countries.append(Country(name: "Réunion", codeAlpha2: "RE", codeAlpha3: "REU", currencyCode: "EUR"))
            countries.append(Country(name: "Saint Barthélemy", codeAlpha2: "BL", codeAlpha3: "BLM", currencyCode: "EUR"))
            countries.append(Country(name: "Saint Helena, Ascension and Tristan da Cunha", codeAlpha2: "SH", codeAlpha3: "SHN", currencyCode: "SHP"))
            countries.append(Country(name: "Saint Kitts and Nevis", codeAlpha2: "KN", codeAlpha3: "KNA", currencyCode: "XCD"))
            countries.append(Country(name: "Saint Lucia", codeAlpha2: "LC", codeAlpha3: "LCA", currencyCode: "XCD"))
            countries.append(Country(name: "Saint Martin (French part)", codeAlpha2: "MF", codeAlpha3: "MAF", currencyCode: "EUR"))
            countries.append(Country(name: "Saint Pierre and Miquelon", codeAlpha2: "PM", codeAlpha3: "SPM", currencyCode: "EUR"))
            countries.append(Country(name: "Saint Vincent and the Grenadines", codeAlpha2: "VC", codeAlpha3: "VCT", currencyCode: "XCD"))
            countries.append(Country(name: "Samoa", codeAlpha2: "WS", codeAlpha3: "WSM", currencyCode: "WST"))
            countries.append(Country(name: "San Marino", codeAlpha2: "SM", codeAlpha3: "SMR", currencyCode: "EUR"))
            countries.append(Country(name: "Sao Tome and Principe", codeAlpha2: "ST", codeAlpha3: "STP", currencyCode: "STD"))
            countries.append(Country(name: "Saudi Arabia", codeAlpha2: "SA", codeAlpha3: "SAU", currencyCode: "SAR"))
            countries.append(Country(name: "Senegal", codeAlpha2: "SN", codeAlpha3: "SEN", currencyCode: "XOF"))
            countries.append(Country(name: "Serbia", codeAlpha2: "RS", codeAlpha3: "SRB", currencyCode: "RSD"))
            countries.append(Country(name: "Seychelles", codeAlpha2: "SC", codeAlpha3: "SYC", currencyCode: "SCR"))
            countries.append(Country(name: "Sierra Leone", codeAlpha2: "SL", codeAlpha3: "SLE", currencyCode: "SLL"))
            countries.append(Country(name: "Singapore", codeAlpha2: "SG", codeAlpha3: "SGP", currencyCode: "SGD"))
            countries.append(Country(name: "Sint Maarten (Dutch part)", codeAlpha2: "SX", codeAlpha3: "SXM", currencyCode: "ANG"))
            countries.append(Country(name: "Slovakia", codeAlpha2: "SK", codeAlpha3: "SVK", currencyCode: "EUR"))
            countries.append(Country(name: "Slovenia", codeAlpha2: "SI", codeAlpha3: "SVN", currencyCode: "EUR"))
            countries.append(Country(name: "Solomon Islands", codeAlpha2: "SB", codeAlpha3: "SLB", currencyCode: "SBD"))
            countries.append(Country(name: "Somalia", codeAlpha2: "SO", codeAlpha3: "SOM", currencyCode: "SOS"))
            countries.append(Country(name: "South Africa", codeAlpha2: "ZA", codeAlpha3: "ZAF", currencyCode: "ZAR"))
            countries.append(Country(name: "South Georgia and the South Sandwich Islands", codeAlpha2: "GS", codeAlpha3: "SGS", currencyCode: ""))
            countries.append(Country(name: "South Sudan", codeAlpha2: "SS", codeAlpha3: "SSD", currencyCode: "SSP"))
            countries.append(Country(name: "Spain", codeAlpha2: "ES", codeAlpha3: "ESP", currencyCode: "EUR"))
            countries.append(Country(name: "Sri Lanka", codeAlpha2: "LK", codeAlpha3: "LKA", currencyCode: "LKR"))
            countries.append(Country(name: "Sudan", codeAlpha2: "SD", codeAlpha3: "SDN", currencyCode: "SDG"))
            countries.append(Country(name: "Suriname", codeAlpha2: "SR", codeAlpha3: "SUR", currencyCode: "SRD"))
            countries.append(Country(name: "Svalbard and Jan Mayen", codeAlpha2: "SJ", codeAlpha3: "SJM", currencyCode: "NOK"))
            countries.append(Country(name: "Swaziland", codeAlpha2: "SZ", codeAlpha3: "SWZ", currencyCode: "SZL"))
            countries.append(Country(name: "Sweden", codeAlpha2: "SE", codeAlpha3: "SWE", currencyCode: "SEK"))
            countries.append(Country(name: "Switzerland", codeAlpha2: "CH", codeAlpha3: "CHE", currencyCode: "CHF"))
            countries.append(Country(name: "Syrian Arab Republic", codeAlpha2: "SY", codeAlpha3: "SYR", currencyCode: "SYP"))
            countries.append(Country(name: "Taiwan", codeAlpha2: "TW", codeAlpha3: "TWN", currencyCode: "TWD"))
            countries.append(Country(name: "Tajikistan", codeAlpha2: "TJ", codeAlpha3: "TJK", currencyCode: "TJS"))
            countries.append(Country(name: "Tanzania, United Republic of", codeAlpha2: "TZ", codeAlpha3: "TZA", currencyCode: "TZS"))
            countries.append(Country(name: "Thailand", codeAlpha2: "TH", codeAlpha3: "THA", currencyCode: "THB"))
            countries.append(Country(name: "Timor-Leste", codeAlpha2: "TL", codeAlpha3: "TLS", currencyCode: "USD"))
            countries.append(Country(name: "Togo", codeAlpha2: "TG", codeAlpha3: "TGO", currencyCode: "XOF"))
            countries.append(Country(name: "Tokelau", codeAlpha2: "TK", codeAlpha3: "TKL", currencyCode: "NZD"))
            countries.append(Country(name: "Tonga", codeAlpha2: "TO", codeAlpha3: "TON", currencyCode: "TOP"))
            countries.append(Country(name: "Trinidad and Tobago", codeAlpha2: "TT", codeAlpha3: "TTO", currencyCode: "TTD")) 
            countries.append(Country(name: "Tunisia", codeAlpha2: "TN", codeAlpha3: "TUN", currencyCode: "TND")) 
            countries.append(Country(name: "Turkey", codeAlpha2: "TR", codeAlpha3: "TUR", currencyCode: "TRY")) 
            countries.append(Country(name: "Turkmenistan", codeAlpha2: "TM", codeAlpha3: "TKM", currencyCode: "TMT")) 
            countries.append(Country(name: "Turks and Caicos Islands", codeAlpha2: "TC", codeAlpha3: "TCA", currencyCode: "USD")) 
            countries.append(Country(name: "Tuvalu", codeAlpha2: "TV", codeAlpha3: "TUV", currencyCode: "AUD")) 
            countries.append(Country(name: "Uganda", codeAlpha2: "UG", codeAlpha3: "UGA", currencyCode: "UGX")) 
            countries.append(Country(name: "Ukraine", codeAlpha2: "UA", codeAlpha3: "UKR", currencyCode: "UAH")) 
            countries.append(Country(name: "United Arab Emirates", codeAlpha2: "AE", codeAlpha3: "ARE", currencyCode: "AED")) 
            countries.append(Country(name: "United Kingdom", codeAlpha2: "GB", codeAlpha3: "GBR", currencyCode: "GBP")) 
            countries.append(Country(name: "United States", codeAlpha2: "US", codeAlpha3: "USA", currencyCode: "USD")) 
            countries.append(Country(name: "United States Minor Outlying Islands", codeAlpha2: "UM", codeAlpha3: "UMI", currencyCode: "USD")) 
            countries.append(Country(name: "Uruguay", codeAlpha2: "UY", codeAlpha3: "URY", currencyCode: "UYU")) 
            countries.append(Country(name: "Uzbekistan", codeAlpha2: "UZ", codeAlpha3: "UZB", currencyCode: "UZS")) 
            countries.append(Country(name: "Vanuatu", codeAlpha2: "VU", codeAlpha3: "VUT", currencyCode: "VUV")) 
            countries.append(Country(name: "Venezuela, Bolivarian Republic of", codeAlpha2: "VE", codeAlpha3: "VEN", currencyCode: "VEF")) 
            countries.append(Country(name: "Viet Nam", codeAlpha2: "VN", codeAlpha3: "VNM", currencyCode: "VND")) 
            countries.append(Country(name: "Virgin Islands, British", codeAlpha2: "VG", codeAlpha3: "VGB", currencyCode: "USD")) 
            countries.append(Country(name: "Virgin Islands, U.S.", codeAlpha2: "VI", codeAlpha3: "VIR", currencyCode: "USD")) 
            countries.append(Country(name: "Wallis and Futuna", codeAlpha2: "WF", codeAlpha3: "WLF", currencyCode: "XPF")) 
            countries.append(Country(name: "Western Sahara", codeAlpha2: "EH", codeAlpha3: "ESH", currencyCode: "MAD")) 
            countries.append(Country(name: "Yemen", codeAlpha2: "YE", codeAlpha3: "YEM", currencyCode: "YER")) 
            countries.append(Country(name: "Zambia", codeAlpha2: "ZM", codeAlpha3: "ZMB", currencyCode: "ZMW")) 
            countries.append(Country(name: "Zimbabwe", codeAlpha2: "ZW", codeAlpha3: "ZWE", currencyCode: "ZWL"))
            
            return countries
        }
    }
    
}
