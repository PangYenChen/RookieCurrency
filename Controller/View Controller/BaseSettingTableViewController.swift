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
    
    @IBOutlet weak var sectionFooterView: UIView!
    
    let stepper: UIStepper
    
    @IBOutlet weak var versionLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    var editedNumberOfDayString: String { fatalError("editedNumberOfDayString has not been implemented") }
    
    var editedBaseCurrencyString: String { fatalError("editedBaseCurrencyString has not been implemented") }
    
    var editedCurrencyOfInterestString: String { fatalError("editedCurrencyOfInterestString has not been implemented") }
    
    // MARK: - methods
    required init?(coder: NSCoder) {
        
        stepper = UIStepper()
        
        super.init(coder: coder)
        
        // stepper
        do {
            let handler = UIAction { [unowned self] _ in stepperValueDidChange() }
            stepper.addAction(handler, for: .primaryActionTriggered)
        }
        
        title = R.string.localizable.setting()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            versionLabel.font = UIFont.preferredFont(forTextStyle: .callout)
            versionLabel.textColor = UIColor.secondaryLabel
            versionLabel.adjustsFontForContentSizeCategory = true
            let appVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            versionLabel.text = R.string.localizable.version(appVersionString ?? "", AppUtility.gitHash)
        }
        
        do {
            dateLabel.font = UIFont.preferredFont(forTextStyle: .callout)
            dateLabel.textColor = UIColor.secondaryLabel
            dateLabel.adjustsFontForContentSizeCategory = true
            let commitDate = Date(timeIntervalSince1970: Double(AppUtility.commitTimestamp))
            let dateString = commitDate.formatted(date: .numeric, time: .complete)
            
            dateLabel.text = R.string.localizable.versionDate(dateString)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let baseCurrencyIndexPath = IndexPath(row: Row.baseCurrency.rawValue, section: 0)
        let currencyOfInterestIndexPath = IndexPath(row: Row.currencyOfInterest.rawValue, section: 0)
        DispatchQueue.main.async { [unowned self] in
            tableView.reloadRows(at: [baseCurrencyIndexPath, currencyOfInterestIndexPath], with: .automatic)
        }
    }
    
    func stepperValueDidChange() {
        fatalError("stepperValueDidChange() has not been implemented")
    }
    
    @IBAction func save() {
        dismiss(animated: true)
    }
    
    func cancel() {
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
                                                    style: .default) { [unowned self] _ in cancel() }
            
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
    @IBSegueAction func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        fatalError("showBaseCurrencyTableViewController(_:) has not been implemented")
    }
    @IBSegueAction func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        fatalError("showCurrencyOfInterestTableViewController(_:) has not been implemented")
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
        
        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        contentConfiguration.textToSecondaryTextVerticalPadding = 4
        
        // font
        do {
            contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
            contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
            
            contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
            contentConfiguration.secondaryTextProperties.color = UIColor.secondaryLabel
            contentConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
        }
        
        // content
        do {
            let row = Row(rawValue: indexPath.row)
            switch row {
            case .numberOfDay:
                contentConfiguration.text = R.string.localizable.numberOfConsideredDay()
                contentConfiguration.secondaryText = editedNumberOfDayString
                contentConfiguration.image = UIImage(systemName: "calendar")
                cell.accessoryView = stepper
            case .baseCurrency:
                contentConfiguration.text = R.string.localizable.baseCurrency()
                contentConfiguration.secondaryText = editedBaseCurrencyString
                contentConfiguration.image = UIImage(systemName: "dollarsign.circle")
                cell.accessoryType = .disclosureIndicator
            case .currencyOfInterest:
                contentConfiguration.text = R.string.localizable.currencyOfInterest()
                contentConfiguration.secondaryText = editedCurrencyOfInterestString
                contentConfiguration.image = UIImage(systemName: "checklist")
                cell.accessoryType = .disclosureIndicator
            case .language:
                contentConfiguration.text = R.string.localizable.language()
                if let languageCode = Bundle.main.preferredLocalizations.first {
                    contentConfiguration.secondaryText = Locale.autoupdatingCurrent.localizedString(forLanguageCode: languageCode)
                }
                contentConfiguration.image = UIImage(systemName: "character")
                cell.accessoryType = .disclosureIndicator
            case .removeFile:
                contentConfiguration.text = R.string.localizable.removeFiles()
                contentConfiguration.secondaryText = R.string.localizable.removeFilesDescription()
                contentConfiguration.image = UIImage(systemName: "folder.badge.minus")
                cell.accessoryType = .none
#if DEBUG
            case .debugInfo:
                contentConfiguration.text = R.string.localizable.debugInfo()
                contentConfiguration.secondaryText = nil
                contentConfiguration.image = UIImage(systemName: "ladybug")
                cell.accessoryType = .disclosureIndicator
#endif
            case nil:
                assertionFailure("###, \(#function), \(self), SettingTableViewController.Row 新增了 case，未處理新增的 case。")
            }
        }
        
        cell.contentConfiguration = contentConfiguration
        
        return cell
    }
}

// MARK: - Table view delegate
extension BaseSettingTableViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let row = Row(rawValue: indexPath.row)
        switch row {
        case .numberOfDay:
            return nil
        case .baseCurrency, .currencyOfInterest, .language, .removeFile:
            return indexPath
#if DEBUG
        case .debugInfo:
            return indexPath
#endif
        case nil:
            assertionFailure("###, \(#function), \(self), SettingTableViewController.Row 新增了 case，未處理新增的 case。")
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row(rawValue: indexPath.row)
        switch row {
        case .numberOfDay:
            assertionFailure("###, \(#function), \(self), number of day 這個 row 在 tableView(_:willSelectRowAt:) 被設定成不能被點")
            
        case .baseCurrency:
            let identifier = R.segue.settingTableViewController.showBaseCurrencyTableViewController.identifier
            performSegue(withIdentifier: identifier, sender: self)
            
        case .currencyOfInterest:
            let identifier = R.segue.settingTableViewController.showCurrencyOfInterestTableViewController.identifier
            performSegue(withIdentifier: identifier, sender: self)
            
        case .language:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            tableView.deselectRow(at: indexPath, animated: true)
            
        case .removeFile:
            RateController.shared.removeCachedAndStoredData()
            tableView.deselectRow(at: indexPath, animated: true)
#if DEBUG
        case .debugInfo:
            let identifier = R.segue.settingTableViewController.showDebugInfo.identifier
            performSegue(withIdentifier: identifier, sender: self)
#endif
            
        case nil:
            assertionFailure("###, \(#function), \(self), SettingTableViewController.Row 新增了 case，未處理新增的 case。")
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        Row(rawValue: indexPath.row) != .numberOfDay
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        section == 0 ? sectionFooterView : nil
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == 0 ? UITableView.automaticDimension : 0
    }
}

// MARK: - Adaptive Presentation Controller Delegate
extension BaseSettingTableViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentCancelAlert(showingSave: true)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("###, \(self), \(#function), aa,")
    }
}

// MARK: - name space
extension BaseSettingTableViewController {
    /// 表示 table view 的 row
    enum Row: Int, CaseIterable {
        case numberOfDay = 0
        case baseCurrency
        case currencyOfInterest
        case language
        case removeFile
#if DEBUG
        case debugInfo
#endif
    }
}
