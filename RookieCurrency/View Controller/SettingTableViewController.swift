//
//  SettingTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {
    
    /// 表示 table view 的 row
    enum Row: Int, CaseIterable {
        case numberOfDay = 0
        case baseCurrency
        case language
    }
    // MARK: - properties
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
#warning("forced unwrap")
    private var stepper: UIStepper!
    
    var resultTableViewController: ResultTableViewController!
    
    private var originalNumberOfDay: Int = 0
    
    private var editedNumberOfDay: Int = 0
    
    private var originalBaseCurrency: Currency = .TWD
    
    private var editedBaseCurrency: Currency = .TWD
    
    private var hasChange: Bool { originalNumberOfDay != editedNumberOfDay || originalBaseCurrency != editedBaseCurrency }
    
    // MARK: - methods
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
    
    @objc private func stepperValueDidChange(_ sender: UIStepper) {
        editedNumberOfDay = Int(sender.value)
        tableView.reloadRows(at: [IndexPath(row: Row.numberOfDay.rawValue, section: 0)], with: .none)
        saveButton.isEnabled = hasChange
        isModalInPresentation = hasChange
    }
    
    @IBSegueAction private func showCurrencyTable(_ coder: NSCoder) -> CurrencyTableViewController? {
        CurrencyTableViewController(coder: coder) { [unowned self] selectedCurrency in
            editedBaseCurrency = selectedCurrency
            saveButton.isEnabled = hasChange
            isModalInPresentation = hasChange
            tableView.reloadRows(at: [IndexPath(row: Row.baseCurrency.rawValue, section: 0)], with: .none)
        }
    }
    
    @IBAction private func save() {
        resultTableViewController.refreshWith(baseCurrency: editedBaseCurrency, andNumberOfDay: editedNumberOfDay)
        dismiss(animated: true)
    }
    
    @IBAction private func didTapCancelButton() {
        if hasChange {
            presentCancelAlert(showingSave: false)
        } else {
            dismiss(animated: true)
        }
    }
    
    private func presentCancelAlert(showingSave: Bool) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if showingSave { // 儲存的 action
            let title = R.string.localizable.cancelAlertSavingTitle()
            let saveAction = UIAlertAction(title: title,
                                           style: .default) { [unowned self] _ in save() }
            alertController.addAction(saveAction)
        }
        
        do { // 捨棄變更的 action
            let title = R.string.localizable.cancelAlertDiscardTitle()
            let discardChangeAction = UIAlertAction(title: title,
                                                    style: .default) { [unowned self] _ in dismiss(animated: true) }
            
            alertController.addAction(discardChangeAction)
        }
        
        do { // 繼續編輯的 action
            let title = R.string.localizable.cancelAlertContinueTitle()
            let continueSettingAction = UIAlertAction(title: title, style: .cancel)
            
            alertController.addAction(continueSettingAction)
        }
        
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
        
        do { // font
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel?.adjustsFontForContentSizeCategory = true
            
            cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        }
        
        do { // content
            switch row {
            case .numberOfDay:
                cell.textLabel?.text = R.string.localizable.numberOfConsideredDay()
                cell.detailTextLabel?.text = "\(editedNumberOfDay)"
                cell.accessoryView = stepper
                cell.imageView?.image = UIImage(systemName: "calendar")
            case .baseCurrency:
                cell.textLabel?.text = R.string.localizable.baseCurrency()
                cell.detailTextLabel?.text = editedBaseCurrency.name
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "dollarsign.square")
            case .language:
                cell.textLabel?.text = R.string.localizable.language()
                if let languageCode = Bundle.main.preferredLocalizations.first {
                    cell.detailTextLabel?.text = Locale.current.localizedString(forLanguageCode: languageCode)
                }
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "character")
            }
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
