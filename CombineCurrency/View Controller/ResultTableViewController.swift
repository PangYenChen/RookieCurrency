//
//  ResultTableViewController.swift
//  CombineCurrency
//
//  Created by Pang-yen Chen on 2020/8/31.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit
import Combine

class ResultTableViewController: UITableViewController {
    
    // MARK: - Property
    private let latestUpdateTimeStampSubject = PassthroughSubject<Int, Never>()
    
    let updateData = PassthroughSubject<(baseCurrency: ResponseDataModel.RateList.Currency, numberOfDay: Int), Never>()
    
    lazy var latestUpdateTimeStampPublisher: AnyPublisher<Int, Never> = {
        latestUpdateTimeStampSubject.eraseToAnyPublisher()
    }()
    
    #warning("這不舒服，不應該給這樣的預設值，但要天大的錯誤才會沒被覆蓋掉。")
    var numberOfDay: Int = -1
    
    var baseCurrency: ResponseDataModel.RateList.Currency = .TWD
    
    private var anyCancellableSet = Set<AnyCancellable>()
    
    var analyzedData: Array<(currency: ResponseDataModel.RateList.Currency, latest: Double, mean: Double, deviation: Double)> = [] {
        didSet {
            self.tableView.reloadData()
        }
    }
    
    var anyCancellable: AnyCancellable?
    
    // MARK: - Method
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(getDataAndUpdateUI), for: .valueChanged)
        
        updateData
            .handleEvents(receiveOutput: { [unowned self] (baseCurrency, numberOfDay) in
                
                self.anyCancellable = RateListSetController.rateListSetPublisher(forDays: numberOfDay)
                    .handleEvents(receiveSubscription: { [unowned self] _ in
                        self.tableView.refreshControl?.beginRefreshing()
                    })
                    .map { [unowned self] (latestRateList, historicalRateListSet) -> Array<(currency: ResponseDataModel.RateList.Currency,latest: Double, mean: Double, deviation: Double)> in
                        
                        self.latestUpdateTimeStampSubject.send(latestRateList.timestamp)
                        
                        return RateListSetAnalyst.analyze(latestRateList: latestRateList,
                                                          historicalRateListSet: historicalRateListSet,
                                                          baseCurrency: baseCurrency)
                            .sorted { $0.value.deviation > $1.value.deviation}
                            .map { (currency: $0.key, latest: $0.value.latest, mean: $0.value.mean, $0.value.deviation)}
                    }
                    .eraseToAnyPublisher()
                    .sink(receiveCompletion: { [unowned self] completion in
                        self.tableView.refreshControl?.endRefreshing()
                        switch completion {
                        case .finished:
                            break
                        case .failure(let error):
                            self.showErrorAlert(error: error)
                        }
                        },
                          receiveValue: { [unowned self] analyzedData in
                            self.tableView.refreshControl?.endRefreshing()
                            self.analyzedData = analyzedData
                    })
            })
            .sink(receiveValue: { _ in})
            .store(in: &anyCancellableSet)
        
    }
    
    
    @objc private func getDataAndUpdateUI() {
        updateData.send((baseCurrency, numberOfDay))
    }
    
    private func showErrorAlert(error: Error) {
        let alertController = UIAlertController(title: "唉呀！出錯啦！", message: error.localizedDescription, preferredStyle: .alert)
        let cancelAlertAction = UIAlertAction(title: "喔，是喔。", style: .cancel) { [unowned self] _ in
            self.dismiss(animated: true)
        }
        
        alertController.addAction(cancelAlertAction)
        present(alertController, animated: true)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return analyzedData.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier")
        
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reuseIdentifier")
        }
        
        let data = analyzedData[indexPath.item]
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
