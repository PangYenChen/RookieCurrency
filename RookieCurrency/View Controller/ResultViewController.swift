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
            baseCurrencyLabel.text = R.string.localizable.baseCurrency(baseCurrency.name)

            resultTableViewController.getDataAndUpdateUI()
        }
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        resultTableViewController.delegate = self
        
        let numberOfDay = UserDefaults.standard.double(forKey: "numberOfDay")
#warning("好像不應該用 double")
        stepper.value = (numberOfDay > 0) ? numberOfDay : 30
        
        numberOfDayLabel.text = R.string.localizable.numberOfConsideredDay("\(Int(stepper.value))")
        
        if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency"),
           let baseCurrency = ResponseDataModel.RateList.Currency(rawValue: baseCurrencyString) {
            self.baseCurrency = baseCurrency
        } else {
            baseCurrency = .TWD
        }
    }
    
    override func stepperValueDidChange(_ sender: UIStepper) {
        numberOfDayLabel.text = R.string.localizable.numberOfConsideredDay("\(Int(stepper.value))")
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
        latestUpdateTimeLabel.text = R.string.localizable.latestUpdateTime(dateString)
    }
    
    func getNumberOfDay() -> Int { Int(stepper.value) }
    
    func getBaseCurrency() -> ResponseDataModel.RateList.Currency { baseCurrency }
}
