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
    private let numberOfDayAndBaseCurrency: CurrentValueSubject<(numberOfDay: Int, baseCurrency: Currency), Never>
    
    private let order: PassthroughSubject<Order, Never>
    
    private let searchText: PassthroughSubject<String, Never>
    
    private let refresh: PassthroughSubject<Void, Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        numberOfDayAndBaseCurrency = CurrentValueSubject((numberOfDay: AppSetting.numberOfDay, baseCurrency: AppSetting.baseCurrency))
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
                    AppSetting.order = order
                    sortItem.menu?.children.first?.subtitle = order.localizedName
                }
                .store(in: &anyCancellableSet)
        }
        
        // subscribe
        do {
            numberOfDayAndBaseCurrency
                .dropFirst()
                .sink { numberOfDay, baseCurrency in
                    AppSetting.numberOfDay = numberOfDay
                    AppSetting.baseCurrency = baseCurrency
                }
                .store(in: &anyCancellableSet)
            
            numberOfDayAndBaseCurrency
                .sink { [unowned self] _ in refreshControl?.beginRefreshing() }
                .store(in: &anyCancellableSet)
            
            let updating = Publishers.CombineLatest(refresh, numberOfDayAndBaseCurrency).share()
            
            let updatingString = updating
                .map { _, _  in R.string.localizable.updating() }
            
            let rateListSetResult = updating
                .flatMap { _, numberOfDayAndBaseCurrency in
                    RateListController.shared
                        .rateListSetPublisher(forDays: numberOfDayAndBaseCurrency.numberOfDay)
                        .convertOutputToResult()
                        .receive(on: DispatchQueue.main)
                }
                .share()
            
            let rateListSetFailure = rateListSetResult
                .resultFailure()
                .share()
            
            rateListSetFailure
                .sink { [unowned self] failure in showErrorAlert(error: failure) }
                .store(in: &anyCancellableSet)
            
            let rateListSetSuccess = rateListSetResult
                .resultSuccess()
                .share()
            
            let latestUpdateTimeString = rateListSetSuccess
                .map { rateListSet in rateListSet.latestRateList.timestamp }
                .map(Double.init)
                .map(Date.init(timeIntervalSince1970:))
                .map(AppSetting.uiDateFormatter.string(from:))
                .map { R.string.localizable.latestUpdateTime($0) }
            
            let updateFailTimeString = rateListSetFailure
                .withLatestFrom(latestUpdateTimeString)
                .map { $1 }
                .prepend("-")
            
            let updateSuccessTimeString = latestUpdateTimeString
            
            Publishers
                .Merge3(updatingString,
                        updateFailTimeString,
                        updateSuccessTimeString)
                .sink { [unowned self] updateResult in latestUpdateTimeItem.title = updateResult }
                .store(in: &anyCancellableSet)
            
            let analyzedDataDictionary = rateListSetSuccess
                .withLatestFrom(numberOfDayAndBaseCurrency)
                .map { rateListSet, numberOfDayAndBaseCurrency in
                    Analyst.analyze(latestRateList: rateListSet.latestRateList,
                                    historicalRateListSet: rateListSet.historicalRateListSet,
                                    baseCurrency: numberOfDayAndBaseCurrency.baseCurrency)
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
            
            let shouldEndRefreshingControl = Publishers.Merge(rateListSetFailure.map { _ in () },
                                                              shouldPopulateTableView.map { _ in () })
            
            shouldEndRefreshingControl
                .sink { [unowned self] _ in refreshControl?.endRefreshing() }
                .store(in: &anyCancellableSet)
        }
        
        // send initial value
        do {
            order.send(AppSetting.order)
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
                                   numberOfDay: numberOfDayAndBaseCurrency.value.numberOfDay,
                                   baseCurrency: numberOfDayAndBaseCurrency.value.baseCurrency,
                                   updateSetting: AnySubscriber(numberOfDayAndBaseCurrency))
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
