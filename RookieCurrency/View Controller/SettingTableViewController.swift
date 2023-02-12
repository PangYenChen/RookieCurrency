//
//  SettingTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class SettingTableViewController: UITableViewController {
    
    // MARK: - properties
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    private var stepper: UIStepper!
    
    var resultTableViewController: ResultTableViewController!
    
    private var originalNumberOfDay: Int = 0
    
    private var editedNumberOfDay: Int = 0
    
    private var originalBaseCurrency: Currency = .TWD
    
    private var editedBaseCurrency: Currency = .TWD
    
    private var hasChange: Bool { originalNumberOfDay != editedNumberOfDay || originalBaseCurrency != editedBaseCurrency }
    
    // MARK: - methods
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        title = R.string.localizable.setting()
    }
    
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
            let handler = UIAction { [unowned self] _ in
                editedNumberOfDay = Int(stepper.value)
                tableView.reloadRows(at: [IndexPath(row: Row.numberOfDay.rawValue, section: 0)], with: .none)
                saveButton.isEnabled = hasChange
                isModalInPresentation = hasChange
            }
            stepper.addAction(handler, for: .primaryActionTriggered)
            stepper.value = Double(resultTableViewController.numberOfDay)
        }
        
        do { // other set up
            isModalInPresentation = hasChange
        }
        
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
        
        do { // font
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel?.adjustsFontForContentSizeCategory = true
            
            cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        }
        
        do { // content
            let row = Row(rawValue: indexPath.row)
            switch row {
            case .numberOfDay:
                cell.textLabel?.text = R.string.localizable.numberOfConsideredDay()
                cell.detailTextLabel?.text = "\(editedNumberOfDay)"
                cell.accessoryView = stepper
                cell.imageView?.image = UIImage(systemName: "calendar")
            case .baseCurrency:
                cell.textLabel?.text = R.string.localizable.baseCurrency()
                cell.detailTextLabel?.text = editedBaseCurrency.localizedString
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "dollarsign.circle")
            case .language:
                cell.textLabel?.text = R.string.localizable.language()
                if let languageCode = Bundle.main.preferredLocalizations.first {
                    cell.detailTextLabel?.text = Locale.current.localizedString(forLanguageCode: languageCode)
                }
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "character")
            default:
                assertionFailure("###, \(#function), \(self), SettingTableViewController.Row 新增了 case，未處理新增的 case。")
            }
        }
        
        return cell
    }
}

// MARK: - Table view delegate
extension SettingTableViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let row = Row(rawValue: indexPath.row)
        switch row {
        case .baseCurrency, .language:
            return indexPath
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row(rawValue: indexPath.row)
        switch row {
        case .baseCurrency:
            performSegue(withIdentifier: R.segue.settingTableViewController.showCurrencyTable, sender: self)
        case .language:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        Row(rawValue: indexPath.row) != .numberOfDay
    }
}

// MARK: - Adaptive Presentation Controller Delegate
extension SettingTableViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentCancelAlert(showingSave: true)
    }
}

// MARK: - name space
extension SettingTableViewController {
    /// 表示 table view 的 row
    enum Row: Int, CaseIterable {
        case numberOfDay = 0
        case baseCurrency
        case language
    }
}
