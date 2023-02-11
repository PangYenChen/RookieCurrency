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
    private var baseCurrency: ResponseDataModel.RateList.Currency

    private var numberOfDay: Int
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        if let baseCurrencyString = UserDefaults.standard.string(forKey: "baseCurrency"),
           let baseCurrency = ResponseDataModel.RateList.Currency(rawValue: baseCurrencyString) {
            self.baseCurrency = baseCurrency
        } else {
            baseCurrency = .TWD
        }
        
        numberOfDay = UserDefaults.standard.integer(forKey: "numberOfDay")
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stepper.value = (numberOfDay > 0) ? Double(numberOfDay) : 30
        
        numberOfDayLabel.text = R.string.localizable.numberOfConsideredDay("\(Int(numberOfDay))")
        baseCurrencyLabel.text = R.string.localizable.baseCurrency(baseCurrency.name)
        
        resultTableViewController.getDataAndUpdateUI()
    }
    
    override func stepperValueDidChange(_ sender: UIStepper) {
        numberOfDay = Int(sender.value)
        numberOfDayLabel.text = R.string.localizable.numberOfConsideredDay("\(Int(stepper.value))")
        UserDefaults.standard.set(stepper.value, forKey: "numberOfDay")
    }
    
    override func didChooseBaseCurrency(_ currency: Currency) {
        baseCurrency = currency
        UserDefaults.standard.set(baseCurrency.rawValue, forKey: "baseCurrency")
        baseCurrencyLabel.text = R.string.localizable.baseCurrency(baseCurrency.name)
        
        resultTableViewController.getDataAndUpdateUI()
    }
    @IBSegueAction func embedTableView(_ coder: NSCoder) -> ResultTableViewController? {
        return ResultTableViewController(coder: coder, resultViewController: self)
    }
}

// MARK: - 跟 child view controller 溝通
extension ResultViewController {
    func updateLatestTime(_ timestamp: Int) {
        let date = Date(timeIntervalSince1970: Double(timestamp))
        let dateString = DateFormatter.uiDateFormatter.string(from: date)
        latestUpdateTimeLabel.text = R.string.localizable.latestUpdateTime(dateString)
    }
    
    func getNumberOfDay() -> Int { Int(stepper.value) }
    
    func getBaseCurrency() -> ResponseDataModel.RateList.Currency { baseCurrency }
}
