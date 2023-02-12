//
//  SettingTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {
    
    enum Row: CaseIterable {
        case numberOfDay
        case baseCurrency
        case language
    }
    
    var stepper: UIStepper!
    
    var resultTableViewController: ResultTableViewController?
    
    init?(coder: NSCoder, resultTableViewController: ResultTableViewController) {
        self.resultTableViewController = resultTableViewController
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        self.resultTableViewController = nil
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do { // stepper
            stepper = UIStepper()
            stepper.addTarget(self,
                              action: #selector(stepperValueDidChange),
                              for: .valueChanged)
        }
        
    }
    
    @objc func stepperValueDidChange(_ sender: UIStepper) {
        print("###, \(#function), \(self), ")
    }
    
}

// MARK: - Table view data source
extension SettingTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = R.reuseIdentifier.settingCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        let row = Row.allCases[indexPath.row]
        
        switch row {
        case .numberOfDay:
            #warning("forced unwarp")
            let numberOfDay = resultTableViewController!.numberOfDay
            cell.textLabel?.text = R.string.localizable.numberOfConsideredDay("\(numberOfDay)")
            cell.accessoryView = stepper
        case .baseCurrency:
#warning("forced unwarp")
            let baseCurrency = resultTableViewController!.baseCurrency
            cell.textLabel?.text = R.string.localizable.baseCurrency(baseCurrency.name)
            cell.accessoryType = .disclosureIndicator
        case .language:
            cell.textLabel?.text = "## 語言"
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
}

// MARK: - Table view delegate
extension SettingTableViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let row = Row.allCases[indexPath.row]
        switch row {
        case .numberOfDay:
            return nil
        case .baseCurrency, .language:
            return indexPath
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row.allCases[indexPath.row]
        switch row {
        case .numberOfDay:
            break
        case .baseCurrency:
            performSegue(withIdentifier: R.segue.settingTableViewController.shwoCurrencyTable, sender: self)
        case .language:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            #warning("要再確認一下")
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = Row.allCases[indexPath.row]
        
        return row != .numberOfDay
    }
}
