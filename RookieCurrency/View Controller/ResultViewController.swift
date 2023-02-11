//
//  ResultViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/5.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

class ResultTableViewController: UITableViewController {
    // MARK: - Private Property
    
    /// 分析過的匯率資料
    private var analyzedDataArray: Array<(currency: ResponseDataModel.RateList.Currency, latest: Double, mean: Double, deviation: Double)> = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        do { // search controller
            navigationItem.searchController = UISearchController()
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.beginRefreshing()
        
        RateListSetController.getRatesSetForDays(numberOfDay: 30) { [unowned self] result in
            switch result {
            case .success(let (latestRateList, historicalRateListSet)):
                let timestamp = latestRateList.timestamp
                
//                resultViewController.updateLatestTime(timestamp)
                #warning("暫時先 hard code base currency")
                analyzedDataArray = RateListSetAnalyst
                    .analyze(latestRateList: latestRateList,
                             historicalRateListSet: historicalRateListSet,
                             baseCurrency: .TWD)
                    .sorted { $0.value.deviation > $1.value.deviation }
                    .map { (currency: $0.key, latest: $0.value.latest, mean: $0.value.mean, $0.value.deviation)}
                
            case .failure(let error):
//                self.showErrorAlert(error: error)
                break
            }
            
            self.tableView.refreshControl?.endRefreshing()
        }
    }
}

extension ResultTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return analyzedDataArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let reusedIdentifier = R.reuseIdentifier.currencyCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
        
        let data = analyzedDataArray[indexPath.item]
        let currency = data.currency
        let deviationString = NumberFormatter.localizedString(from: NSNumber(value: data.deviation), number: .decimal)
        let meanString = NumberFormatter.localizedString(from: NSNumber(value: data.mean), number: .decimal)
        let latestString = NumberFormatter.localizedString(from: NSNumber(value: data.latest), number: .decimal)
        
        cell.textLabel?.text = "\(currency) " + currency.name + deviationString
        cell.textLabel?.adjustsFontForContentSizeCategory = true
        cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        cell.textLabel?.textColor = data.deviation < 0 ? .systemGreen : .systemRed
        
        cell.detailTextLabel?.text = R.string.localizable.currencyCellDetail(meanString, latestString)
        cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
        
        return cell
    }
}
    
