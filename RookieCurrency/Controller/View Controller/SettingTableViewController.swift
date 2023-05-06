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
    
    private let completionHandler: (Int, ResponseDataModel.CurrencyCode) -> Void
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: ResponseDataModel.CurrencyCode,
                   currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
                   completionHandler: @escaping (Int, ResponseDataModel.CurrencyCode) -> Void) {
        
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
            
            cell.detailTextLabel?.text = editedNumberOfDayString
        }
    }
    
    @IBAction override func save() {
        completionHandler(editedNumberOfDay, editedBaseCurrency)
        super.save()
    }
    
    @IBAction private func didTapCancelButton() {
        hasChange ? presentCancelAlert(showingSave: false) : dismiss(animated: true)
    }
    
    // MARK: - Navigation
    override func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        
        let currencyTableViewModel = CurrencyTableViewController
            .ViewModel(baseCurrencyCode: editedBaseCurrency) { [unowned self] selectedBaseCurrency in
                self.editedBaseCurrency = selectedBaseCurrency
                let baseCurrencyIndexPath = IndexPath(row: Row.baseCurrency.rawValue, section: 0)
                tableView.reloadRows(at: [baseCurrencyIndexPath], with: .automatic)
            }
        
        return CurrencyTableViewController(coder: coder, viewModel: currencyTableViewModel)
    }
    
    override func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        fatalError("暫時先拿掉")
//        let selectionCurrencyOfInterestViewModel = BaseCurrencyTableViewController.SelectionCurrencyOfInterestViewModel(currencyOfInterest: editedCurrencyOfInterest) { [unowned self] selectedCurrencyOfInterest in
//            editedCurrencyOfInterest = selectedCurrencyOfInterest
//        }
//
//        return CurrencyTableViewController(coder: coder, viewModel: selectionCurrencyOfInterestViewModel)
    }
    
}
