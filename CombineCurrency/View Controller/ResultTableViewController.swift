//
//  ResultTableViewController.swift
//  CombineCurrency
//
//  Created by Pang-yen Chen on 2020/9/2.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit
import Combine

class ResultTableViewController: BaseResultTableViewController {
    // MARK: - stored properties
    private let numberOfDay: CurrentValueSubject<Int, Never>
    
    private let baseCurrency: CurrentValueSubject<Currency, Never>
    
    private let order: CurrentValueSubject<Order, Never>
    
    private let searchText: CurrentValueSubject<String, Never>
    
    private let latestUpdateTime: CurrentValueSubject<Date?, Never>
    
    private let refresh: CurrentValueSubject<Void, Never>
    
    /// 分析過的匯率資料
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        numberOfDay = CurrentValueSubject(UserDefaults.numberOfDay)
        baseCurrency = CurrentValueSubject(UserDefaults.baseCurrency)
        order = CurrentValueSubject(UserDefaults.order)
        searchText = CurrentValueSubject(String())
        latestUpdateTime =  CurrentValueSubject(nil)
        anyCancellableSet = Set<AnyCancellable>()
        refresh = CurrentValueSubject(())

        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        latestUpdateTime
            .map { latestUpdateTime in latestUpdateTime.map(DateFormatter.uiDateFormatter.string(from:)) }
            .map { latestUpdateTimeString in latestUpdateTimeString ?? "-" }
            .map { R.string.localizable.latestUpdateTime($0) }
            .assign(to: \.title, on: latestUpdateTimeItem)
            .store(in: &anyCancellableSet)
        
        // sort item menu
        do {
            order.first()
                .sink { [unowned self] order in
                    let increasingAction = UIAction(title: Order.increasing.localizedName,
                                                    image: UIImage(systemName: "arrow.up.right"),
                                                    handler: { [unowned self] _ in setOrder(.increasing) })
                    let decreasingAction =  UIAction(title: Order.decreasing.localizedName,
                                                     image: UIImage(systemName: "arrow.down.right"),
                                                     handler: { [unowned self] _ in setOrder(.decreasing) })
                    switch order {
                    case .increasing:
                        increasingAction.state = .on
                    case .decreasing:
                        decreasingAction.state = .on
                    }
                    
                    let sortMenu = UIMenu(title: R.string.localizable.sortedBy(),
                                          image: UIImage(systemName: "arrow.up.arrow.down"),
                                          options: .singleSelection,
                                          children: [increasingAction, decreasingAction])
                    
                    sortItem.menu = UIMenu(title: "",
                                           options: .singleSelection,
                                           children: [sortMenu])
                }
                .store(in: &anyCancellableSet)
            
            order
                .sink { [unowned self] order in
                    UserDefaults.order = order
                    sortItem.menu?.children.first?.subtitle = order.localizedName
                }
                .store(in: &anyCancellableSet)
        }
        
        // refresh
        do {
            let sharedRateListSetResultPublisher = refresh
                .handleEvents(receiveOutput: { [unowned self] _ in
                    refreshControl?.beginRefreshing()
                    latestUpdateTimeItem.title = R.string.localizable.updating()
                })
                .withLatestFrom(numberOfDay)
                .flatMap { _, numberOfDay in
                    RateListSetController
                        .rateListSetPublisher(forDays: numberOfDay)
                        .convertOutputToResult()
                }
                .share()
            
            sharedRateListSetResultPublisher
                .resultFailure()
                .sink(receiveValue: showErrorAlert(error:))
                .store(in: &anyCancellableSet)
            
            
            let sharedRateListSetPublisher = sharedRateListSetResultPublisher
                .compactMap { try? $0.get() }
                .share()
            
            sharedRateListSetPublisher
                .sink  { [unowned self] (latestRateList, _) in
                    let timestamp = Double(latestRateList.timestamp)
                    latestUpdateTime.send(Date(timeIntervalSince1970: timestamp))
                }
                .store(in: &anyCancellableSet)
            
            let analyzedDataDictionaryPublisher = sharedRateListSetPublisher
                .withLatestFrom(baseCurrency)
                .map { output -> [Currency: (latest: Double, mean: Double, deviation: Double)] in
                    let ((latestRateList, historicalRateListSet), baseCurrency) = output
                    return RateListSetAnalyst.analyze(latestRateList: latestRateList,
                                                      historicalRateListSet: historicalRateListSet,
                                                      baseCurrency: baseCurrency)
                }
            
            Publishers.CombineLatest3(analyzedDataDictionaryPublisher, order, searchText)
                .sink { [unowned self] analyzedDataDictionary, order, searchText in
                    self.analyzedDataDictionary = analyzedDataDictionary
                    populateTableView(analyzedDataDictionary: analyzedDataDictionary,
                                      order: order,
                                      searchText: searchText)
                    refreshControl?.endRefreshing()
                }
                .store(in: &anyCancellableSet)
            
        }
    }
    
    override func setOrder(_ order: BaseResultTableViewController.Order) {
        self.order.send(order)
    }
    
    override func refreshControlTriggered() {
        refresh.send()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        
        let updateSetting = PassthroughSubject<(numberOfDay: Int, baseCurrency: Currency), Never>()
        
        updateSetting
            .sink { [unowned self] (editedNumberOfDay: Int, editedBaseCurrency: Currency) in
                do { // base currency
                    baseCurrency.send(editedBaseCurrency)
                    UserDefaults.baseCurrency = editedBaseCurrency
                }
                
                do { // number Of Day
                    numberOfDay.send(editedNumberOfDay)
                    UserDefaults.numberOfDay = editedNumberOfDay
                }
                
                refresh.send()
            }
            .store(in: &anyCancellableSet)
        
        return SettingTableViewController(coder: coder,
                                          numberOfDay: numberOfDay.value,
                                          baseCurrency: baseCurrency.value,
                                          updateSetting: AnySubscriber(updateSetting))
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchText.send("")
    }
}
