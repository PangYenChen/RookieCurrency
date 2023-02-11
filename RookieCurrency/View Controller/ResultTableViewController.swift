//
//  ResultTableViewController.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - Property
    let resultViewController: ResultViewController
    
    // MARK: - Methods
    init?(coder: NSCoder, resultViewController: ResultViewController) {
        self.resultViewController = resultViewController
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getDataAndUpdateUI() {
        tableView.refreshControl?.beginRefreshing()
        
        let numberOfDay = resultViewController.getNumberOfDay()
        
        RateListSetController.getRatesSetForDays(numberOfDay: numberOfDay) { [unowned self] result in
            switch result {
            case .success(let (latestRateList, historicalRateListSet)):
                let timestamp = latestRateList.timestamp
                
                resultViewController.updateLatestTime(timestamp)
                
                analyzedDataArray = RateListSetAnalyst
                    .analyze(latestRateList: latestRateList,
                             historicalRateListSet: historicalRateListSet,
                             baseCurrency: resultViewController.getBaseCurrency())
                    .sorted { $0.value.deviation > $1.value.deviation}
                    .map { (currency: $0.key, latest: $0.value.latest, mean: $0.value.mean, $0.value.deviation)}
                
            case .failure(let error):
                self.showErrorAlert(error: error)
            }
            
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}


protocol ResultDelegate: AnyObject {
    func updateLatestTime(_ timestamp: Int)
    
    func getNumberOfDay() -> Int
    
    func getBaseCurrency() -> ResponseDataModel.RateList.Currency
}
