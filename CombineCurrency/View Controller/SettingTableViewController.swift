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
    
    override var editedBaseCurrencyString: String { editedBaseCurrency.value.localizedString }
    
    private let originalNumberOfDay: Int
    
    private let editedNumberOfDay: CurrentValueSubject<Int, Never>
    
    private let originalBaseCurrency: Currency
    
    private let editedBaseCurrency: CurrentValueSubject<Currency, Never>
    
    private let hasChanges: AnyPublisher<Bool, Never>
    
    private let didTapCancelButtonSubject: PassthroughSubject<Void, Never>
    
    private let didTapSaveButtonSubject: PassthroughSubject<Void, Never>
    
    private let updateSetting: PassthroughSubject<(numberOfDay: Int, baseCurrency: Currency), Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: Currency,
                   updateSetting: PassthroughSubject<(numberOfDay: Int, baseCurrency: Currency), Never>) {
        
        do { // number of day
            originalNumberOfDay = numberOfDay
            editedNumberOfDay = CurrentValueSubject(numberOfDay)
        }
        
        
        do { // base currency
            originalBaseCurrency = baseCurrency
            editedBaseCurrency = CurrentValueSubject(baseCurrency)
        }
        
        do {
            self.updateSetting = updateSetting
        }
        
        didTapCancelButtonSubject = PassthroughSubject()
        
        didTapSaveButtonSubject = PassthroughSubject()
        
        do {
            let numberOfDayHasChanges = editedNumberOfDay.map { $0 != numberOfDay }
            let baseCurrencyHasChanges = editedBaseCurrency.map { $0 != baseCurrency }
            hasChanges = Publishers.CombineLatest(numberOfDayHasChanges, baseCurrencyHasChanges)
                .map { $0 || $1 }
                .eraseToAnyPublisher()
        }

        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
        
        do { // stepper
            stepper.value = Double(numberOfDay)
        }
        do { // stepper
            let handler = UIAction { [unowned self] _ in editedNumberOfDay.send(Int(stepper.value)) }
            stepper.addAction(handler, for: .primaryActionTriggered)
        }
        
        do { // other set up
            title = R.string.localizable.setting()
        }
        
        didTapCancelButtonSubject
            .withLatestFrom(hasChanges)
            .sink { [unowned self] _, hasChanges in hasChanges ? presentCancelAlert(showingSave: false) : dismiss(animated: true) }
            .store(in: &anyCancellableSet)
        
        didTapSaveButtonSubject
            .withLatestFrom(editedNumberOfDay)
            .map { $1 }
            .withLatestFrom(editedBaseCurrency)
            .sink { [unowned self] (numberOfDay, baseCurrency) in
                updateSetting.send((numberOfDay, baseCurrency))
                dismiss(animated: true)
            }
            .store(in: &anyCancellableSet)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            editedNumberOfDay
                .sink { [unowned self] editedNumberOfDay in
                    tableView.reloadRows(at: [IndexPath(row: Row.numberOfDay.rawValue, section: 0)], with: .none)
                }
                .store(in: &anyCancellableSet)
            
            editedBaseCurrency
                .sink { [unowned self] editedBaseCurrency in
                    tableView.reloadRows(at: [IndexPath(row: Row.baseCurrency.rawValue, section: 0)], with: .none)
                }
                .store(in: &anyCancellableSet)
            
            hasChanges
                .sink { [unowned self] hasChanges in
                    saveButton.isEnabled = hasChanges
                    isModalInPresentation = hasChanges
                }
                .store(in: &anyCancellableSet)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBSegueAction override func showCurrencyTable(_ coder: NSCoder) -> CurrencyTableViewController? {
        let editedBaseCurrency = PassthroughSubject<Currency, Never>()
        
        editedBaseCurrency
            .sink { [unowned self] editedBaseCurrency in self.editedBaseCurrency.send(editedBaseCurrency) }
            .store(in: &anyCancellableSet)
        
        return CurrencyTableViewController(coder: coder, editedBaseCurrency: editedBaseCurrency)
    }
    
    @IBAction override func save() {
        didTapSaveButtonSubject.send()
        super.save()
    }
    
    @IBAction private func didTapCancelButton() {
        didTapCancelButtonSubject.send()
    }
}
