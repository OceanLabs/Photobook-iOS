//
//  CountryPickerTableViewController.swift
//  Shopify
//
//  Created by Konstadinos Karayannis on 08/09/2017.
//  Copyright © 2017 Kite.ly. All rights reserved.
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
