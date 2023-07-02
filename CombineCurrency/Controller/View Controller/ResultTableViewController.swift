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
    private let userSetting: CurrentValueSubject<UserSetting, Never>
    
    private let order: PassthroughSubject<Order, Never>
    
    private let searchText: PassthroughSubject<String, Never>
    
    private let refresh: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        userSetting = CurrentValueSubject((AppUtility.numberOfDay, AppUtility.baseCurrency, AppUtility.currencyOfInterest))
        order = PassthroughSubject<Order, Never>()
        searchText = PassthroughSubject<String, Never>()
        refresh = PassthroughSubject<Void, Never>()
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // sort item menu
        do {
            order.first()
                .sink { [unowned self] order in
                    let increasingAction = UIAction(title: Order.increasing.localizedName,
                                                    image: UIImage(systemName: "arrow.up.right"),
                                                    handler: { [unowned self] _ in setOrder(.increasing) })
                    let decreasingAction = UIAction(title: Order.decreasing.localizedName,
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
                .dropFirst()
                .sink { [unowned self] order in
                    AppUtility.order = order
                    sortItem.menu?.children.first?.subtitle = order.localizedName
                }
                .store(in: &anyCancellableSet)
        }
        
        // subscribe
        do {
            userSetting
                .dropFirst()
                .sink { numberOfDay, baseCurrency, currencyOfInterest in
                    AppUtility.numberOfDay = numberOfDay
                    AppUtility.baseCurrency = baseCurrency
                    AppUtility.currencyOfInterest = currencyOfInterest
                }
                .store(in: &anyCancellableSet)
            
            userSetting
                .sink { [unowned self] _ in refreshControl?.beginRefreshing() }
                .store(in: &anyCancellableSet)
            
            let updating = Publishers.CombineLatest(refresh, userSetting).share()
            
            let updatingString = updating
                .map { _, _  in R.string.localizable.updating() }
            
            let rateSetResult = updating
                .flatMap { _, numberOfDayAndBaseCurrency in
                    RateController.shared
                        .ratePublisher(numberOfDay: numberOfDayAndBaseCurrency.numberOfDay)
                        .convertOutputToResult()
                        .receive(on: DispatchQueue.main)
                }
                .share()
            
            let rateSetFailure = rateSetResult
                .resultFailure()
                .share()
            
            rateSetFailure
                .sink { [unowned self] failure in presentAlert(error: failure) }
                .store(in: &anyCancellableSet)
            
            let rateSetSuccess = rateSetResult
                .resultSuccess()
                .share()
            
            let latestUpdateTimeString = rateSetSuccess
                .map { rateSet in rateSet.latestRate.timestamp }
                .map(Double.init)
                .map(Date.init(timeIntervalSince1970:))
                .map { $0.formatted(date: .omitted, time: .standard) }
                .map { R.string.localizable.latestUpdateTime($0) }
            
            let updateFailTimeString = rateSetFailure
                .withLatestFrom(latestUpdateTimeString)
                .map { $1 }
                .prepend("-")
            
            let updateSuccessTimeString = latestUpdateTimeString
            
            Publishers
                .Merge3(updatingString,
                        updateFailTimeString,
                        updateSuccessTimeString)
                .sink { [unowned self] updateResult in updatingStatusItem.title = updateResult }
                .store(in: &anyCancellableSet)
            
            let analyzedDataDictionary = rateSetSuccess
                .withLatestFrom(userSetting)
                .map { rateSet, userSetting in
                    return Analyst.analyze(currencyOfInterest: userSetting.currencyOfInterest,
                                           latestRate: rateSet.latestRate,
                                           historicalRateSet: rateSet.historicalRateSet,
                                           baseCurrency: userSetting.baseCurrency)
                    .compactMapValues { result in try? result.get() }
#warning("還沒處理錯誤，要提示使用者即將刪掉本地的資料，重新從網路上拿")
                }
            
            let shouldPopulateTableView = Publishers.CombineLatest3(analyzedDataDictionary, order, searchText).share()
            
            shouldPopulateTableView
                .sink { [unowned self] analyzedDataDictionary, order, searchText  in
                    self.analyzedDataDictionary = analyzedDataDictionary
                    populateTableView(analyzedDataDictionary: analyzedDataDictionary,
                                      order: order,
                                      searchText: searchText)
                }
                .store(in: &anyCancellableSet)
            
            let shouldEndRefreshingControl = Publishers.Merge(rateSetFailure.map { _ in () },
                                                              shouldPopulateTableView.map { _ in () })
            
            shouldEndRefreshingControl
                .sink { [unowned self] _ in refreshControl?.endRefreshing() }
                .store(in: &anyCancellableSet)
        }
        
        // send initial value
        do {
            order.send(AppUtility.order)
            searchText.send("")
            refresh.send()
        }
    }
    
    override func setOrder(_ order: BaseResultTableViewController.Order) {
        self.order.send(order)
    }
    
    override func refreshControlTriggered() {
        refresh.send()
    }
    
    @IBSegueAction override func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        SettingTableViewController(coder: coder,
                                   userSetting: userSetting.value,
                                   updateSetting: AnySubscriber(userSetting))
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchText.send("")
    }
}
