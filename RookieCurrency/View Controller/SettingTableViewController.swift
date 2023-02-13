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
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    
    private let stepper: UIStepper
    
    private let completionHandler: (Int, Currency) -> Void
    
    private let originalNumberOfDay: Int
    
    private var editedNumberOfDay: Int?
    
    private var numberOfDay: Int { editedNumberOfDay ?? originalNumberOfDay }
    
    private let originalBaseCurrency: Currency
    
    private var editedBaseCurrency: Currency?
    
    private var baseCurrency: Currency { editedBaseCurrency ?? originalBaseCurrency }
    
    private var hasChange: Bool { originalNumberOfDay != editedNumberOfDay || originalBaseCurrency != editedBaseCurrency }
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: Currency,
                   completionHandler: @escaping (Int, Currency) -> Void) {
        
        do { // number of day
            originalNumberOfDay = numberOfDay
            editedNumberOfDay = numberOfDay
        }
        
        do { // stepper
            stepper = UIStepper()
            stepper.value = Double(numberOfDay)
        }
        
        do { // base currency
            originalBaseCurrency = baseCurrency
            editedBaseCurrency = baseCurrency
        }
        
        do {
            self.completionHandler = completionHandler
        }

        super.init(coder: coder)
        
        do { // stepper
            let handler = UIAction { [unowned self] _ in
                editedNumberOfDay = Int(stepper.value)
                tableView.reloadRows(at: [IndexPath(row: Row.numberOfDay.rawValue, section: 0)], with: .none)
                saveButton.isEnabled = hasChange
                isModalInPresentation = hasChange
            }
            stepper.addAction(handler, for: .primaryActionTriggered)
        }
        
        do { // other set up
            isModalInPresentation = hasChange
            title = R.string.localizable.setting()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        completionHandler(numberOfDay, baseCurrency)
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
        
        if showingSave { // 儲存的 action，只有在下拉的時候加上這個 action。
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
                cell.detailTextLabel?.text = String(numberOfDay)
                cell.accessoryView = stepper
                cell.imageView?.image = UIImage(systemName: "calendar")
            case .baseCurrency:
                cell.textLabel?.text = R.string.localizable.baseCurrency()
                cell.detailTextLabel?.text = baseCurrency.localizedString
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
private extension SettingTableViewController {
    /// 表示 table view 的 row
    enum Row: Int, CaseIterable {
        case numberOfDay = 0
        case baseCurrency
        case language
    }
}
