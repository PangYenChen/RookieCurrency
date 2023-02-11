//
//  ResultTableViewController.swift
//  CombineCurrency
//
//  Created by Pang-yen Chen on 2020/8/31.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    
    // MARK: - Property
    private let latestUpdateTimeStampSubject = PassthroughSubject<Int, Never>()
    
    let updateData = PassthroughSubject<(baseCurrency: ResponseDataModel.RateList.Currency, numberOfDay: Int), Never>()
    
    lazy var latestUpdateTimeStampPublisher: AnyPublisher<Int, Never> = {
        latestUpdateTimeStampSubject.eraseToAnyPublisher()
    }()
    
    var numberOfDay: Int
    
    var baseCurrency: ResponseDataModel.RateList.Currency
    
    private var anyCancellableSet = Set<AnyCancellable>()
    
    private var anyCancellable: AnyCancellable?
    
    // MARK: - Method
    
    required init?(coder: NSCoder, resultViewController: ResultViewController) {
        numberOfDay = resultViewController.numberOfDay.value
        baseCurrency = resultViewController.baseCurrency.value
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.refreshControl = UIRefreshControl()
        tableView.refreshControl?.addTarget(self, action: #selector(getDataAndUpdateUI), for: .valueChanged)
        
        updateData
            .handleEvents(receiveOutput: { [unowned self] (baseCurrency, numberOfDay) in
                
                anyCancellable = RateListSetController.rateListSetPublisher(forDays: numberOfDay)
                    .handleEvents(receiveSubscription: { [unowned self] _ in
                        self.tableView.refreshControl?.beginRefreshing()
                    })
                    .map { [unowned self] (latestRateList, historicalRateListSet) -> Array<(currency: ResponseDataModel.RateList.Currency,latest: Double, mean: Double, deviation: Double)> in
                        
                        self.latestUpdateTimeStampSubject.send(latestRateList.timestamp)
                        
                        return RateListSetAnalyst.analyze(latestRateList: latestRateList,
                                                          historicalRateListSet: historicalRateListSet,
                                                          baseCurrency: baseCurrency)
                            .sorted { $0.value.deviation > $1.value.deviation }
                            .map { (currency: $0.key, latest: $0.value.latest, mean: $0.value.mean, $0.value.deviation)}
                    }
                    .eraseToAnyPublisher()
                    .sink(
                        receiveCompletion: { [unowned self] completion in
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
                            self.analyzedDataArray = analyzedData
                        }
                    )
            })
            .sink(receiveValue: { _ in })
            .store(in: &anyCancellableSet)
        
    }
    
    override func getDataAndUpdateUI() {
        updateData.send((baseCurrency, numberOfDay))
    }
}
