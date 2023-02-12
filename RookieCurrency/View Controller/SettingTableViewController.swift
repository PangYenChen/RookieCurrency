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
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    var stepper: UIStepper!
#warning("forced unwrap")
    var resultTableViewController: ResultTableViewController!
    
    var originalNumberOfDay: Int = 0
    
    var editedNumberOfDay: Int = 0
    
    var originalBaseCurrency: Currency = .TWD
    
    var editedBaseCurrency: Currency = .TWD
    
    var hasChange: Bool { originalNumberOfDay != editedNumberOfDay || originalBaseCurrency != editedBaseCurrency }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do { // number Of Day
            originalNumberOfDay = resultTableViewController.numberOfDay
            editedNumberOfDay = resultTableViewController.numberOfDay
        }
        
        do { // base currency
            originalBaseCurrency = resultTableViewController.baseCurrency
            editedBaseCurrency = resultTableViewController.baseCurrency
        }
        
        do { // stepper
            stepper = UIStepper()
            stepper.addTarget(self,
                              action: #selector(stepperValueDidChange),
                              for: .valueChanged)
            stepper.value = Double(resultTableViewController.numberOfDay)
        }
        
        do { // other set up
            isModalInPresentation = hasChange
        }
        
    }
    
    @objc func stepperValueDidChange(_ sender: UIStepper) {
        editedNumberOfDay = Int(sender.value)
        #warning("改拿row的方式")
        tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: .none)
        saveButton.isEnabled = hasChange
        isModalInPresentation = hasChange
    }
    
    @IBSegueAction func showCurrencyTable(_ coder: NSCoder) -> CurrencyTableViewController? {
        CurrencyTableViewController(coder: coder) { [unowned self] selectedCurrency in
            editedBaseCurrency = selectedCurrency
#warning("改拿row的方式")
            saveButton.isEnabled = hasChange
            isModalInPresentation = hasChange
            tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
        }
    }
    
    @IBAction func save() {
        resultTableViewController.numberOfDay = editedNumberOfDay
        resultTableViewController.baseCurrency = editedBaseCurrency
        resultTableViewController.refresh()
        dismiss(animated: true)
    }
    
    @IBAction func didTapCancelButton() {
        if hasChange {
            presentCancelAlert(showingSave: false)
        } else {
            dismiss(animated: true)
        }
    }
    
    private func presentCancelAlert(showingSave: Bool) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if showingSave {
            let saveAction = UIAlertAction(title: "## 儲存",
                                           style: .default) { [unowned self] _ in save() }
            alertController.addAction(saveAction)
        }
        
        let discardChangeAction = UIAlertAction(title: "## 捨棄變更",
                                                style: .default) { [unowned self] _ in dismiss(animated: true) }
        
        alertController.addAction(discardChangeAction)
        
        let continueSettingAction = UIAlertAction(title: "## 繼續設定", style: .cancel)
        
        alertController.addAction(continueSettingAction)
        
        present(alertController, animated: true)
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
        
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        
        switch row {
        case .numberOfDay:
            cell.textLabel?.text = R.string.localizable.numberOfConsideredDay()
            cell.detailTextLabel?.text = "\(editedNumberOfDay)"
            cell.accessoryView = stepper
        case .baseCurrency:
            cell.textLabel?.text = R.string.localizable.baseCurrency()
            cell.detailTextLabel?.text = editedBaseCurrency.name
            cell.accessoryType = .disclosureIndicator
        case .language:
            cell.textLabel?.text = R.string.localizable.language()
            if let languageCode = Bundle.main.preferredLocalizations.first {
                cell.detailTextLabel?.text = Locale.current.localizedString(forLanguageCode: languageCode)
            }
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
            performSegue(withIdentifier: R.segue.settingTableViewController.showCurrencyTable, sender: self)
        case .language:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        let row = Row.allCases[indexPath.row]
        
        return row != .numberOfDay
    }
}

// MARK: - Adaptive Presentation Controller Delegate
extension SettingTableViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentCancelAlert(showingSave: true)
    }
}
