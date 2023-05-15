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
    
    private let editedNumberOfDay: CurrentValueSubject<Int, Never>
    
    private let editedBaseCurrency: CurrentValueSubject<ResponseDataModel.CurrencyCode, Never>
    
    private let hasChanges: AnyPublisher<Bool, Never>
    
    private let didTapCancelButtonSubject: PassthroughSubject<Void, Never>
    
    private let didTapSaveButtonSubject: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: ResponseDataModel.CurrencyCode,
                   updateSetting: AnySubscriber<(numberOfDay: Int, baseCurrency: ResponseDataModel.CurrencyCode), Never>) {
        
        editedNumberOfDay = CurrentValueSubject(numberOfDay)
        
        editedBaseCurrency = CurrentValueSubject(baseCurrency)
        
        didTapCancelButtonSubject = PassthroughSubject()
        
        didTapSaveButtonSubject = PassthroughSubject()
        
        // has changes
        do {
            let numberOfDayHasChanges = editedNumberOfDay.map { $0 != numberOfDay }
            let baseCurrencyHasChanges = editedBaseCurrency.map { $0 != baseCurrency }
            hasChanges = Publishers.CombineLatest(numberOfDayHasChanges, baseCurrencyHasChanges)
                .map { $0 || $1 }
                .eraseToAnyPublisher()
        }

        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
        
        stepper.value = Double(numberOfDay)
        
        didTapCancelButtonSubject
            .withLatestFrom(hasChanges)
            .sink { [unowned self] _, hasChanges in hasChanges ? presentCancelAlert(showingSave: false) : dismiss(animated: true) }
            .store(in: &anyCancellableSet)
        
        didTapSaveButtonSubject
            .withLatestFrom(editedNumberOfDay)
            .map { $1 }
            .withLatestFrom(editedBaseCurrency)
            .map { (numberOfDay: $0, baseCurrency: $1) }
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
        fatalError()
    }
}
