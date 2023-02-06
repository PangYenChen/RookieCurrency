//
//  ResultTableViewController.swift
//  RookieCurrency
//
//  Created by Pang-yen Chen on 2020/6/1.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit

/// 呈現分析結果的 view controller
class ResultTableViewController: UITableViewController {
    // MARK: - Property
    weak var delegate: ResultDelegate!
    
    /// 分析過的匯率資料
    var analyzedDataArray: Array<(currency: ResponseDataModel.RateList.Currency, latest: Double, mean: Double, deviation: Double)> = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self,
                                            action: #selector(getDataAndUpdateUI),
                                            for: .valueChanged)
    }
    
    @objc func getDataAndUpdateUI() {
        tableView.refreshControl?.beginRefreshing()
        let numberOfDay = delegate.getNumberOfDay()
        
        RateListSetController.getRatesSetForDays(numberOfDay: numberOfDay) {[unowned self] result in
            switch result {
            case .success(let (latestRateList, historicalRateListSet)):
                let timestamp = latestRateList.timestamp
                
                self.delegate.updateLatestTime(timestamp)
                
                self.analyzedDataArray = RateListSetAnalyst
                    .analyze(latestRateList: latestRateList,
                             historicalRateListSet: historicalRateListSet,
                             baseCurrency: self.delegate.getBaseCurrency())
                    .sorted { $0.value.deviation > $1.value.deviation}
                    .map { (currency: $0.key, latest: $0.value.latest, mean: $0.value.mean, $0.value.deviation)}
                
            case .failure(let error):
                self.showErrorAlert(error: error)
            }
            
            self.tableView.refreshControl?.endRefreshing()
        }
    }
    
    private func showErrorAlert(error: Error) {
        #warning("這出乎我的意料，要向下轉型才讀得到正確的 localizedDescription，要查一下資料。")
        let message: String
        
        if let errorMessage = error as? ResponseDataModel.ServerError {
            message = errorMessage.localizedDescription
        } else {
            message = error.localizedDescription
        }
        
        let alertController = UIAlertController(title: "唉呀！出錯啦！", message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "喔，是喔。", style: .cancel) { _ in
            alertController.dismiss(animated: true)
        }
        alertController.addAction(alertAction)
        
        self.present(alertController, animated: true)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return analyzedDataArray.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        }
        
        let data = analyzedDataArray[indexPath.item]
        let currency = data.currency
        let deviationString = NumberFormatter.localizedString(from: NSNumber(value: data.deviation), number: .decimal)
        let meanString = NumberFormatter.localizedString(from: NSNumber(value: data.mean), number: .decimal)
        let latestString = NumberFormatter.localizedString(from: NSNumber(value: data.latest), number: .decimal)
        
        cell.textLabel?.text = "\(currency) " + currency.name + deviationString
        cell.detailTextLabel?.text = "過去平均：" + meanString + "，今天匯率：" + latestString
            
        cell.textLabel?.textColor = data.deviation < 0 ? .green : .red
        
        return cell
    }
}

protocol ResultDelegate: AnyObject {
    func updateLatestTime(_ timestamp: Int)
    
    func getNumberOfDay() -> Int
    
    func getBaseCurrency() -> ResponseDataModel.RateList.Currency
}
