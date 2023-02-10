//
//  ResultViewController.swift
//  CombineCurrency
//
//  Created by Pang-yen Chen on 2020/9/2.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit
import Combine

class ResultViewController: BaseResultViewController {
    
    // MARK: - property
    private var anyCancellableSet = Set<AnyCancellable>()
    
    private var numberOfDay: CurrentValueSubject<Int, Never>
    
    private var baseCurrency: CurrentValueSubject<ResponseDataModel.RateList.Currency, Never>
       
    // MARK: - Method
    required init?(coder: NSCoder) {
        if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency"),
           let baseCurrency = ResponseDataModel.RateList.Currency.init(rawValue: baseCurrencyString) {
            self.baseCurrency = CurrentValueSubject(baseCurrency)
        } else {
            let defaultCurrency = Currency.TWD
            baseCurrency = CurrentValueSubject(.TWD)
        }
        
        let userSettingNumber = UserDefaults.standard.integer(forKey: "numberOfDay")
        if userSettingNumber > 0 {
            numberOfDay = CurrentValueSubject(userSettingNumber)
        } else {
            let defaultNumber = 33
            numberOfDay = CurrentValueSubject(defaultNumber)
        }
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubscription()
    }
    
    private func setupSubscription() {
        resultTableViewController.latestUpdateTimeStampPublisher
            .map(Double.init)
            .map(Date.init(timeIntervalSince1970:))
            .map(DateFormatter.uiDateFormatter.string(from:))
            .map { R.string.localizable.latestUpdateTime($0) }
            .assign(to: \.text, on: latestUpdateTimeLabel)
            .store(in: &anyCancellableSet)
        
        
        do { // number of day
            numberOfDay
                .first()
                .map(Double.init)
                .assign(to: \.value, on: stepper)
                .store(in: &anyCancellableSet)
            
            numberOfDay
                .map(String.init)
                .map { R.string.localizable.numberOfConsideredDay($0) }
                .assign(to: \.text, on: numberOfDayLabel)
                .store(in: &anyCancellableSet)
            
            numberOfDay
                .dropFirst()
                .sink { UserDefaults.standard.set($0, forKey: "numberOfDay") }
                .store(in: &anyCancellableSet)
            
            numberOfDay
                .sink { [unowned self] numberOfDay in resultTableViewController.numberOfDay = numberOfDay }
                .store(in: &anyCancellableSet)
        }
        
        
        do { // base currency
            baseCurrency
                .dropFirst()
                .map { baseCurrency -> String in baseCurrency.rawValue}
                .sink { UserDefaults.standard.set($0, forKey: "baseCurrency") }
                .store(in: &anyCancellableSet)
            
            baseCurrency
                .map { R.string.localizable.baseCurrency($0.name) }
                .assign(to: \.text, on: baseCurrencyLabel)
                .store(in: &anyCancellableSet)
            
            baseCurrency
                .sink { [unowned self] baseCurrency in
                    resultTableViewController.baseCurrency = baseCurrency
                    resultTableViewController.updateData.send((baseCurrency, self.numberOfDay.value))
                }
            .store(in: &anyCancellableSet)
        }
    }
    
    override func stepperValueDidChange(_ sender: UIStepper) {
        numberOfDay.send(Int(sender.value))
    }
    
    override func didChooseBaseCurrency(_ currency: Currency) {
        baseCurrency.send(currency)
    }
}
