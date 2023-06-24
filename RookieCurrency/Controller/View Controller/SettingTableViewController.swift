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
    
    override var editedBaseCurrencyString: String {
        Locale.autoupdatingCurrent.localizedString(forCurrencyCode: editedBaseCurrency) ?? editedBaseCurrency
    }
    
    override var editedCurrencyOfInterestString: String {
        let editedCurrencyDisplayString = editedCurrencyOfInterest
            .map { currencyCode in Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? currencyCode }
            .sorted()
        
        return ListFormatter.localizedString(byJoining: editedCurrencyDisplayString)
    }
    
    private let originalNumberOfDay: Int
    
    private var editedNumberOfDay: Int
    
    private let originalBaseCurrency: ResponseDataModel.CurrencyCode
    
    private var editedBaseCurrency: ResponseDataModel.CurrencyCode
    
    private let originalCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    private var editedCurrencyOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    private var hasChange: Bool {
        originalNumberOfDay != editedNumberOfDay ||
        originalBaseCurrency != editedBaseCurrency ||
        originalCurrencyOfInterest != editedCurrencyOfInterest
    }
    
    private let completionHandler: (Int, ResponseDataModel.CurrencyCode, Set<ResponseDataModel.CurrencyCode>) -> Void
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: ResponseDataModel.CurrencyCode,
                   currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
                   completionHandler: @escaping (Int, ResponseDataModel.CurrencyCode, Set<ResponseDataModel.CurrencyCode>) -> Void) {
        
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
        
        // currency of interest
        do {
            originalCurrencyOfInterest = currencyOfInterest
            editedCurrencyOfInterest = currencyOfInterest
        }
        
        self.completionHandler = completionHandler
        
        super.init(coder: coder)
        
        stepper.value = Double(numberOfDay)

        isModalInPresentation = hasChange
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func stepperValueDidChange() {
        editedNumberOfDay = Int(stepper.value)

        saveButton.isEnabled = hasChange
        isModalInPresentation = hasChange
        
        // update number of day ui
        do {
            let numberOfDayIndexPath = IndexPath(row: Row.numberOfDay.rawValue, section: 0)

            guard let cell = tableView.cellForRow(at: numberOfDayIndexPath) else {
                assertionFailure("###, \(#function), \(self), 拿不到設定 number of day 的 cell。")
                return
            }

            guard var contentConfiguration = cell.contentConfiguration as? UIListContentConfiguration else {
                assertionFailure("###, \(#function), \(self), 在 data source method 中，cell 的 content configuration 應該要是 UIListContentConfiguration，但是中途被改掉了。")
                return
            }
            
            contentConfiguration.secondaryText = editedNumberOfDayString

            cell.contentConfiguration = contentConfiguration
        }
    }
    
    @IBAction override func save() {
        completionHandler(editedNumberOfDay, editedBaseCurrency, editedCurrencyOfInterest)
        super.save()
    }
    
    @IBAction private func didTapCancelButton() {
        hasChange ? presentCancelAlert(showingSave: false) : dismiss(animated: true)
    }
    
    // MARK: - Navigation
    override func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        
        let baseCurrencySelectionStrategy = CurrencyTableViewController
            .BaseCurrencySelectionStrategy(baseCurrencyCode: editedBaseCurrency) { [unowned self] selectedBaseCurrency in
                editedBaseCurrency = selectedBaseCurrency
                saveButton.isEnabled = hasChange
                isModalInPresentation = hasChange
                
                let baseCurrencyIndexPath = IndexPath(row: Row.baseCurrency.rawValue, section: 0)
                DispatchQueue.main.async { [unowned self] in
                    tableView.reloadRows(at: [baseCurrencyIndexPath], with: .automatic)
                }
            }
        
        return CurrencyTableViewController(coder: coder, strategy: baseCurrencySelectionStrategy)
    }
    
    override func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        
        let currencyOfInterestSelectionStrategy = CurrencyTableViewController
            .CurrencyOfInterestSelectionStrategy(currencyOfInterest: editedCurrencyOfInterest) { [unowned self] selectedCurrencyOfInterest in
                editedCurrencyOfInterest = selectedCurrencyOfInterest
                saveButton.isEnabled = hasChange
                isModalInPresentation = hasChange
                
                let currencyOfInterestIndexPath = IndexPath(row: Row.currencyOfInterest.rawValue, section: 0)
                DispatchQueue.main.async { [unowned self] in
                    tableView.reloadRows(at: [currencyOfInterestIndexPath], with: .automatic)
                }
            }

        return CurrencyTableViewController(coder: coder, strategy: currencyOfInterestSelectionStrategy)
    }
    
}
