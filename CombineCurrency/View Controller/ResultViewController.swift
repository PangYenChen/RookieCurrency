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
    
    var numberOfDay: CurrentValueSubject<Int, Never>!
    
    private var baseCurrency: CurrentValueSubject<ResponseDataModel.RateList.Currency, Never>!
       
    // MARK: - Method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupSubscription()
    }
    
    private func setupSubscription() {
        
        if let child = children.first as? ResultTableViewController {
            child.latestUpdateTimeStampPublisher
                .map(Double.init)
                .map(Date.init(timeIntervalSince1970:))
                .map(DateFormatter.uiDateFormatter.string(from:))
                .assign(to: \.text, on: latestUpdateTimeLabel)
                .store(in: &anyCancellableSet)
        }
        
        // number of day
        do {
            let userSettingNumber = UserDefaults.standard.integer(forKey: "numberOfDay")
            if userSettingNumber > 0 {
                numberOfDay = CurrentValueSubject(userSettingNumber)
                stepper.value = Double(userSettingNumber)
            } else {
                let defaultNumber = 33
                numberOfDay = CurrentValueSubject.init(defaultNumber)
                stepper.value = Double(defaultNumber)
            }
            
            numberOfDay
                .map(String.init)
                .assign(to: \.text, on: numberOfDayTextField)
                .store(in: &anyCancellableSet)
            
            numberOfDay
                .dropFirst()
                .sink { UserDefaults.standard.set($0, forKey: "numberOfDay")}
                .store(in: &anyCancellableSet)
            
            numberOfDay
                .sink { [unowned self] numberOfDay in
                    if let resultTableViewController = self.children.first as? ResultTableViewController {
                        resultTableViewController.numberOfDay = numberOfDay
                    }
                }
                .store(in: &anyCancellableSet)
        }
        
        // base currency
        do {
            if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency") {
                if let baseCurrency = ResponseDataModel.RateList.Currency.init(rawValue: baseCurrencyString) {
                    self.baseCurrency = CurrentValueSubject(baseCurrency)
                } else {
                    self.baseCurrency = CurrentValueSubject(.TWD)
                }
            } else {
                baseCurrency = CurrentValueSubject(.TWD)
            }
            
            baseCurrency
                .dropFirst()
                .map { baseCurrency -> String in baseCurrency.rawValue}
                .sink { UserDefaults.standard.set($0, forKey: "baseCurrency")}
                .store(in: &anyCancellableSet)
            
            baseCurrency
                .map { $0.name}
                .assign(to: \.text, on: baseCurrencyLabel)
                .store(in: &anyCancellableSet)
            
            baseCurrency
                .sink { [unowned self] baseCurrency in
                    if let resultTableViewController = self.children.first as? ResultTableViewController {
                        resultTableViewController.baseCurrency = baseCurrency
                        resultTableViewController.updateData.send((baseCurrency, self.numberOfDay.value))
                    }
                }
            .store(in: &anyCancellableSet)
        }
    }
    
    override func stepperValueDidChange(_ sender: UIStepper) {
        numberOfDay.send(Int(sender.value))
    }
    
    override func chooseBaseCurrency(_ sender: UIButton) {
        let alertController = UIAlertController(title: "請選擇基準備別", message: nil, preferredStyle: .actionSheet)
        
        for currency in ResponseDataModel.RateList.Currency.allCases {
            let alertAction = UIAlertAction(title: currency.name, style: .default) { [unowned self] (_) in
                self.baseCurrency.send(currency)
            }
            
            alertController.addAction(alertAction)
        }
        
        let cancelAlertAction = UIAlertAction(title: "取消", style: .cancel) { (_) in
            self.dismiss(animated: true)
        }
        
        alertController.addAction(cancelAlertAction)
        
        present(alertController, animated: true)
    }
}
