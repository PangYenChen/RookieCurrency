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
        Locale.autoupdatingCurrent.localizedString(forCurrencyCode: editedBaseCurrency) ??
        AppUtility.supportedSymbols?[editedBaseCurrency] ??
        editedBaseCurrency
    }
    
    override var editedCurrencyOfInterestString: String {
        let editedCurrencyDisplayString = editedCurrencyOfInterest
            .map { currencyCode in
                Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ??
                AppUtility.supportedSymbols?[currencyCode] ??
                currencyCode
            }
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
    
    private let saveCompletionHandler: (Int, ResponseDataModel.CurrencyCode, Set<ResponseDataModel.CurrencyCode>) -> Void
    
    private let cancelCompletionHandler: () -> Void
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: ResponseDataModel.CurrencyCode,
                   currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
                   saveCompletionHandler: @escaping (Int, ResponseDataModel.CurrencyCode, Set<ResponseDataModel.CurrencyCode>) -> Void,
                   cancelCompletionHandler: @escaping () -> Void) {
        
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
        
        self.saveCompletionHandler = saveCompletionHandler
        self.cancelCompletionHandler = cancelCompletionHandler
        
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
        saveCompletionHandler(editedNumberOfDay, editedBaseCurrency, editedCurrencyOfInterest)
        super.save()
    }
    
    override func cancel() {
        super.cancel()
        cancelCompletionHandler()
    }
    
    @IBAction private func didTapCancelButton() {
        hasChange ? presentCancelAlert(showingSave: false) : cancel()
    }
    
    // MARK: - Navigation
    override func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        
        let baseCurrencySelectionStrategy = CurrencyTableViewController
            .BaseCurrencySelectionStrategy(baseCurrencyCode: editedBaseCurrency) { [unowned self] selectedBaseCurrency in
                editedBaseCurrency = selectedBaseCurrency
                saveButton.isEnabled = hasChange
                isModalInPresentation = hasChange
            }
        
        return CurrencyTableViewController(coder: coder, strategy: baseCurrencySelectionStrategy)
    }
    
    override func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        
        let currencyOfInterestSelectionStrategy = CurrencyTableViewController
            .CurrencyOfInterestSelectionStrategy(currencyOfInterest: editedCurrencyOfInterest) { [unowned self] selectedCurrencyOfInterest in
                editedCurrencyOfInterest = selectedCurrencyOfInterest
                saveButton.isEnabled = hasChange
                isModalInPresentation = hasChange
            }

        return CurrencyTableViewController(coder: coder, strategy: currencyOfInterestSelectionStrategy)
    }
    
}
