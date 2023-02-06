//
//  BaseResultTableViewController.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/6.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit

/// An abstract base class for view controller displaying analyzed result.
/// This class is designed to be subclassed.
class BaseResultTableViewController: UITableViewController {
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
        fatalError("getDataAndUpdateUI() has not been implemented")
    }
    
    func showErrorAlert(error: Error) {
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
        
        let reusedIdentifier = R.reuseIdentifier.currencyCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
        
        let data = analyzedDataArray[indexPath.item]
        let currency = data.currency
        let deviationString = NumberFormatter.localizedString(from: NSNumber(value: data.deviation), number: .decimal)
        let meanString = NumberFormatter.localizedString(from: NSNumber(value: data.mean), number: .decimal)
        let latestString = NumberFormatter.localizedString(from: NSNumber(value: data.latest), number: .decimal)
        
        cell.textLabel?.text = "\(currency) " + currency.name + deviationString
        cell.detailTextLabel?.text = "過去平均：" + meanString + "，今天匯率：" + latestString
        
        cell.textLabel?.textColor = data.deviation < 0 ? .systemGreen : .systemRed
        
        return cell
    }
}
