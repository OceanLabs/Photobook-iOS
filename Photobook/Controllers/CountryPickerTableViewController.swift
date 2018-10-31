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

protocol CountryPickerTableViewControllerDelegate: class {
    func countryPickerDidPick(country: Country)
}

class CountryPickerTableViewController: UITableViewController {
    
    weak var delegate: CountryPickerTableViewControllerDelegate?
    var selectedCountry: Country?
    private var sections = [[Country]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = NSLocalizedString("CountryPicker/Title", value: "Choose Country", comment: "Title for the country picker screen")
        prepareSections()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Find the indexPath of the currently selected country and scroll to it
        var sectionCount = 0
        sectionLoop: for section in sections {
            var rowCount = 0
            for country in section {
                if country.name == selectedCountry?.name {
                    tableView.scrollToRow(at: IndexPath(row: rowCount, section: sectionCount), at: .middle, animated: false)
                    break sectionLoop
                }
                rowCount += 1
            }
            sectionCount += 1
        }
        
    }
    
    private func prepareSections(){
        var lastSectionIndexChar : Character = " "
        var countriesInSection = [Country]()
        for country in Country.countries{
            guard let indexChar = country.name.first else { continue }
            if indexChar != lastSectionIndexChar{
                lastSectionIndexChar = indexChar
                if !countriesInSection.isEmpty {
                    sections.append(countriesInSection)
                }
                countriesInSection = [Country]()
            }
            
            countriesInSection.append(country)
        }
        sections.append(countriesInSection)
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sections[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "country", for: indexPath)

        let countryName = sections[indexPath.section][indexPath.row].name
        cell.textLabel?.text = countryName
        
        let selected = selectedCountry?.name == countryName
        cell.accessoryType = selected ? .checkmark : .none
        
        cell.accessibilityLabel = countryName
        cell.accessibilityHint = selected ? nil : CommonLocalizedStrings.accessibilityDoubleTapToSelectListItem

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.countryPickerDidPick(country: sections[indexPath.section][indexPath.row])
        
        // It's nice to see the checkmark update for the split second before this vc is dismissed
        for cell in tableView.visibleCells{
            cell.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        
        self.navigationController?.popViewController(animated: true)
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        var titles = [String]()
        for countries in sections{
            guard let firstChar = countries.first?.name.first else { continue }
            titles.append(String(firstChar))
        }
        
        return titles
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let firstChar = sections[section].first?.name.first else { return nil }
        return String(firstChar)
    }

}
