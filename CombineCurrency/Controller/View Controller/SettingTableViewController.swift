//
//  SettingTableViewController.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/2/17.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit
import Combine

class SettingTableViewController: BaseSettingTableViewController {
    
    // MARK: - properties
    override var editedNumberOfDayString: String { String(editedNumberOfDay.value) }
    
    override var editedBaseCurrencyString: String {
        Locale.autoupdatingCurrent.localizedString(forCurrencyCode: editedBaseCurrency.value) ?? editedBaseCurrency.value
    }
    
    override var editedCurrencyOfInterestString: String {
        let editedCurrencyDisplayString = editedCurrencyOfInterest.value
            .map { currencyCode in Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ?? currencyCode }
            .sorted()
        
        return ListFormatter.localizedString(byJoining: editedCurrencyDisplayString)
    }
    
    private let editedNumberOfDay: CurrentValueSubject<Int, Never>
    
    private let editedBaseCurrency: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    private let editedCurrencyOfInterest: CurrentValueSubject<Set<ResponseDataModel.CurrencyCode>, Never>
    
    private let hasChanges: AnyPublisher<Bool, Never>
    
    private let didTapCancelButtonSubject: PassthroughSubject<Void, Never>
    
    private let didTapSaveButtonSubject: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   userSetting: AppUtility.UserSetting,
                   updateSetting: AnySubscriber<(numberOfDay: Int, baseCurrency: ResponseDataModel.CurrencyCode, currencyOfInterest: Set<ResponseDataModel.CurrencyCode>), Never>) {
        
        editedNumberOfDay = CurrentValueSubject(userSetting.numberOfDay)
        
        editedBaseCurrency = CurrentValueSubject(userSetting.baseCurrency)
        
        editedCurrencyOfInterest = CurrentValueSubject(userSetting.currencyOfInterest)
        
        didTapCancelButtonSubject = PassthroughSubject()
        
        didTapSaveButtonSubject = PassthroughSubject()
        
        // has changes
        do {
            let numberOfDayHasChanges = editedNumberOfDay.map { $0 != userSetting.numberOfDay }
            let baseCurrencyHasChanges = editedBaseCurrency.map { $0 != userSetting.baseCurrency }
            let currencyOfInterestHasChanges = editedCurrencyOfInterest.map { $0 != userSetting.currencyOfInterest }
            hasChanges = Publishers.CombineLatest3(numberOfDayHasChanges, baseCurrencyHasChanges, currencyOfInterestHasChanges)
                .map { $0 || $1 || $2 }
                .eraseToAnyPublisher()
        }
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
        
        stepper.value = Double(userSetting.numberOfDay)
        
        didTapCancelButtonSubject
            .withLatestFrom(hasChanges)
            .sink { [unowned self] _, hasChanges in hasChanges ? presentCancelAlert(showingSave: false) : dismiss(animated: true) }
            .store(in: &anyCancellableSet)
        
        didTapSaveButtonSubject
            .withLatestFrom(editedNumberOfDay)
            .map { $1 }
            .withLatestFrom(editedBaseCurrency)
            .withLatestFrom(editedCurrencyOfInterest)
            .map { (numberOfDay: $0.0, baseCurrency: $0.1, currencyOfInterest: $1) }
            .subscribe(updateSetting)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        editedNumberOfDay
            .dropFirst()
            .sink { [unowned self] _ in
                
                let numberOfDayRow = IndexPath(row: Row.numberOfDay.rawValue, section: 0)
                
                guard let cell = tableView.cellForRow(at: numberOfDayRow) else {
                    assertionFailure("###, \(#function), \(self), 拿不到設定 number of day 的 cell。")
                    return
                }
                
                cell.detailTextLabel?.text = editedNumberOfDayString
            }
            .store(in: &anyCancellableSet)
        
        editedBaseCurrency
            .sink { [unowned self] _ in tableView.reloadRows(at: [IndexPath(row: Row.baseCurrency.rawValue, section: 0)], with: .none) }
            .store(in: &anyCancellableSet)
        
        editedCurrencyOfInterest
            .sink { [unowned self] currencyOfInterest in tableView.reloadRows(at: [IndexPath(row: Row.currencyOfInterest.rawValue, section: 0)], with: .none) }
            .store(in: &anyCancellableSet)
        
        hasChanges
            .sink { [unowned self] hasChanges in
                saveButton.isEnabled = hasChanges
                isModalInPresentation = hasChanges
            }
            .store(in: &anyCancellableSet)
    }
    
    override func stepperValueDidChange() {
        editedNumberOfDay.send(Int(stepper.value))
    }
    
    @IBAction override func save() {
        didTapSaveButtonSubject.send()
        super.save()
    }
    
    @IBAction private func didTapCancelButton() {
        didTapCancelButtonSubject.send()
    }
    
    // MARK: - Navigation
    override func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        let strategy = CurrencyTableViewController
            .BaseCurrencySelectionStrategy(baseCurrencyCode: editedBaseCurrency.value,
                                           selectedBaseCurrencyCode: AnySubscriber(editedBaseCurrency))
        
        return CurrencyTableViewController(coder: coder, strategy: strategy)
    }
    
    override func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        let strategy = CurrencyTableViewController
            .CurrencyOfInterestSelectionStrategy(currencyOfInterest: editedCurrencyOfInterest.value,
                                                 selectedCurrencyOfInterest: AnySubscriber(editedCurrencyOfInterest))
        
        return CurrencyTableViewController(coder: coder, strategy: strategy)
    }
}
