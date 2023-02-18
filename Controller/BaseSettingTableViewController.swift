//
//  BaseSettingTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/18.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class BaseSettingTableViewController: UITableViewController {
    
    // MARK: - properties
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    let stepper: UIStepper
    
    var editedNumberOfDayString: String { fatalError("editedNumberOfDayString has not been implemented") }
    
    var editedBaseCurrencyString: String { fatalError("editedBaseCurrencyString has not been implemented") }
    
    // MARK: - methods
    required init?(coder: NSCoder) {
        
        stepper = UIStepper()
        
        super.init(coder: coder)
        
        do { // stepper
            let handler = UIAction { [unowned self] _ in stepperValueDidChange() }
            stepper.addAction(handler, for: .primaryActionTriggered)
        }
        
        do { // other set up
            title = R.string.localizable.setting()
        }
    }
    
    func stepperValueDidChange() {
        fatalError("stepperValueDidChange() has not been implemented")
    }
    
    @IBAction func save() {
        dismiss(animated: true)
    }
    
    func presentCancelAlert(showingSave: Bool) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 儲存的 action，只有在下拉的時候加上這個 action。
        if showingSave {
            let title = R.string.localizable.cancelAlertSavingTitle()
            let saveAction = UIAlertAction(title: title,
                                           style: .default) { [unowned self] _ in save() }
            alertController.addAction(saveAction)
        }
        
        // 捨棄變更的 action
        do {
            let title = R.string.localizable.cancelAlertDiscardTitle()
            let discardChangeAction = UIAlertAction(title: title,
                                                    style: .default) { [unowned self] _ in dismiss(animated: true) }
            
            alertController.addAction(discardChangeAction)
        }
        
        // 繼續編輯的 action
        do {
            let title = R.string.localizable.cancelAlertContinueTitle()
            let continueSettingAction = UIAlertAction(title: title, style: .cancel)
            
            alertController.addAction(continueSettingAction)
        }
        
        present(alertController, animated: true)
    }
    
    // MARK: - Navigation
    @IBSegueAction func showCurrencyTable(_ coder: NSCoder) -> CurrencyTableViewController? {
        fatalError("showCurrencyTable(_:) has not been implemented")
    }
}

// MARK: - Table view data source
extension BaseSettingTableViewController {
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
                cell.detailTextLabel?.text = editedNumberOfDayString
                cell.accessoryView = stepper
                cell.imageView?.image = UIImage(systemName: "calendar")
            case .baseCurrency:
                cell.textLabel?.text = R.string.localizable.baseCurrency()
                cell.detailTextLabel?.text = editedBaseCurrencyString
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
extension BaseSettingTableViewController {
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
            let identifier = R.segue.settingTableViewController.showCurrencyTable.identifier
            performSegue(withIdentifier: identifier, sender: self)
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
extension BaseSettingTableViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentCancelAlert(showingSave: true)
    }
}

// MARK: - name space
extension BaseSettingTableViewController {
    /// 表示 table view 的 row
    enum Row: Int, CaseIterable {
        case numberOfDay = 0
        case baseCurrency
        case language
    }
}
