//
//  SettingTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/12.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class SettingTableViewController: BaseSettingTableViewController {
    
    // MARK: - properties
    override var editedNumberOfDayString: String { String(editedNumberOfDay) }
    
    override var editedBaseCurrencyString: String { editedBaseCurrency.localizedString }
    
    private let completionHandler: (Int, Currency) -> Void
    
    private let originalNumberOfDay: Int
    
    private var editedNumberOfDay: Int
    
    private let originalBaseCurrency: Currency
    
    private var editedBaseCurrency: Currency
    
    private var hasChange: Bool { originalNumberOfDay != editedNumberOfDay || originalBaseCurrency != editedBaseCurrency }
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: Currency,
                   completionHandler: @escaping (Int, Currency) -> Void) {
        
        // number of day
        do {
            originalNumberOfDay = numberOfDay
            editedNumberOfDay = numberOfDay
        }
        
        // base currency
        do {
            originalBaseCurrency = baseCurrency
            editedBaseCurrency = baseCurrency
        }
        
        self.completionHandler = completionHandler
        
        super.init(coder: coder)
        
        stepper.value = Double(numberOfDay)

        // other set up
        do {
            isModalInPresentation = hasChange
            title = R.string.localizable.setting()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func stepperValueDidChange() {
        editedNumberOfDay = Int(stepper.value)
        tableView.reloadRows(at: [IndexPath(row: Row.numberOfDay.rawValue, section: 0)], with: .none)
        saveButton.isEnabled = hasChange
        isModalInPresentation = hasChange
    }
    
    @IBSegueAction override func showCurrencyTable(_ coder: NSCoder) -> CurrencyTableViewController? {
        CurrencyTableViewController(coder: coder) { [unowned self] selectedCurrency in
            editedBaseCurrency = selectedCurrency
            saveButton.isEnabled = hasChange
            isModalInPresentation = hasChange
            tableView.reloadRows(at: [IndexPath(row: Row.baseCurrency.rawValue, section: 0)], with: .none)
        }
    }
    
    @IBAction override func save() {
        completionHandler(editedNumberOfDay, editedBaseCurrency)
        super.save()
    }
    
    @IBAction private func didTapCancelButton() {
        hasChange ? presentCancelAlert(showingSave: false) : dismiss(animated: true)
    }
    
    private func presentCancelAlert(showingSave: Bool) {
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
}
