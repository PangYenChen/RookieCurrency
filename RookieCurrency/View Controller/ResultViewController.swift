//
//  ResultViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/5.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class ResultViewController: BaseResultViewController {
    // MARK: - private property
    private var baseCurrency: ResponseDataModel.RateList.Currency = .TWD {
        didSet {
            UserDefaults.standard.set(baseCurrency.rawValue, forKey: "baseCurrency")
            baseCurrencyLabel.text = baseCurrency.name
            
            if let resultTableViewController = children.first as? ResultTableViewController {
                resultTableViewController.getDataAndUpdateUI()
            }
        }
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        numberOfDayTitle.text = R.string.localizable.numberOfConsideredDay()
        
        guard let resultTableViewController = children.first as? ResultTableViewController else {
            fatalError()
        }
        resultTableViewController.delegate = self
        
        let numberOfDay = UserDefaults.standard.double(forKey: "numberOfDay")
        stepper.value = (numberOfDay > 0) ? numberOfDay : 30
        
        numberOfDayTextField.text = "\(Int(stepper.value))"
        
        if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency"),
           let baseCurrency = ResponseDataModel.RateList.Currency(rawValue: baseCurrencyString) {
            self.baseCurrency = baseCurrency
        } else {
            baseCurrency = .TWD
        }
    }
    
    override func stepperValueDidChange(_ sender: UIStepper) {
        numberOfDayTextField.text = "\(Int(stepper.value))"
        UserDefaults.standard.set(stepper.value, forKey: "numberOfDay")
    }
    
    override func chooseBaseCurrency(_ sender: UIButton) {
        let alertController = UIAlertController(title: "請選擇基準備別", message: nil, preferredStyle: .actionSheet)
        
        for currency in ResponseDataModel.RateList.Currency.allCases {
            let alertAction = UIAlertAction(title: currency.name, style: .default) { [unowned self] (_) in
                self.baseCurrency = currency
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

// MARK: - 跟 child view controller 溝通
extension ResultViewController: ResultDelegate {
    func updateLatestTime(_ timestamp: Int) {
        let date = Date(timeIntervalSince1970: Double(timestamp))
        let dateString = DateFormatter.uiDateFormatter.string(from: date)
        latestUpdateTimeLabel.text = dateString
    }
    
    func getNumberOfDay() -> Int { Int(stepper.value) }
    
    func getBaseCurrency() -> ResponseDataModel.RateList.Currency { baseCurrency }
}
