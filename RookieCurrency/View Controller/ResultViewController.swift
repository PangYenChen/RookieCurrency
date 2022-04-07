//
//  ResultViewController.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/7/22.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    // MARK: - Property
    @IBOutlet weak var numberOfDayField: UITextField!
    @IBOutlet weak var stepper: UIStepper!
    @IBOutlet weak var latestTimeLabel: UILabel!
    @IBOutlet weak var baseCurrencyLabel: UILabel!
    
    private var baseCurrency: ResponseDataModel.RateList.Currency = .TWD {
        didSet {
            UserDefaults.standard.set(baseCurrency.rawValue, forKey: "baseCurrency")
            baseCurrencyLabel.text = baseCurrency.name
            
            if let resultTableViewController = children.first as? ResultTableViewController {
                resultTableViewController.getDataAndUpdateUI()
            }
        }
    }
    
    // MARK: - Method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let resultTableViewController = children.first as? ResultTableViewController else {
            fatalError()
        }
        resultTableViewController.delegate = self
        
        let numberOfDay = UserDefaults.standard.double(forKey: "numberOfDay")
        stepper.value = (numberOfDay > 0) ? numberOfDay : 30
        
        numberOfDayField.text = "\(Int(stepper.value))"
        
        if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency"),
            let baseCurrency = ResponseDataModel.RateList.Currency(rawValue: baseCurrencyString) {
            self.baseCurrency = baseCurrency
        } else {
            baseCurrency = .TWD
        }
    }
    
    @IBAction func stepperValueDidChange(_ sender: UIStepper) {
        numberOfDayField.text = "\(Int(stepper.value))"
        UserDefaults.standard.set(stepper.value, forKey: "numberOfDay")
    }
    
    @IBAction func chooseBaseCurrency(_ sender: UIButton) {
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

/// 跟 child view controller 溝通
extension ResultViewController: ResultDelegate {
    func updateLatestTime(_ timestamp: Int) {
        let date = Date(timeIntervalSince1970: Double(timestamp))
        let dateString = DateFormatter.uiDateFormatter.string(from: date)
        latestTimeLabel.text = dateString
    }
    
    func getNumberOfDay() -> Int { Int(stepper.value) }
    
    func getBaseCurrency() -> ResponseDataModel.RateList.Currency { baseCurrency}
}
