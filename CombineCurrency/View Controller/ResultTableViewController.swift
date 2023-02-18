//
//  ResultTableViewController.swift
//  CombineCurrency
//
//  Created by Pang-yen Chen on 2020/9/2.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import UIKit
import Combine

class ResultTableViewController: UITableViewController {
    
    // MARK: - IBOutlet
    @IBOutlet private weak var latestUpdateTimeItem: UIBarButtonItem!
    
    @IBOutlet private weak var sortItem: UIBarButtonItem!
    
    // MARK: - stored properties
    private let numberOfDay: CurrentValueSubject<Int, Never>
    
    private let baseCurrency: CurrentValueSubject<Currency, Never>
    
    private let order: CurrentValueSubject<Order, Never>
    
    private let searchText: CurrentValueSubject<String, Never>
    
    private let latestUpdateTime: CurrentValueSubject<Date?, Never>
    
    private let refresh: CurrentValueSubject<Void, Never>
    
    /// 分析過的匯率資料
    private var analyzedDataDictionary: [Currency: (latest: Double, mean: Double, deviation: Double)]
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    private var dataSource: DataSource!
    
    // MARK: - Methods
    required init?(coder: NSCoder) {
        
        do { // numberOfDay
            numberOfDay = CurrentValueSubject(UserDefaults.numberOfDay)
        }
        
        do { // baseCurrency
            baseCurrency = CurrentValueSubject(UserDefaults.baseCurrency)
        }
        
        do { // order
            order = CurrentValueSubject(UserDefaults.order)
        }
        
        do { // search Text
            searchText = CurrentValueSubject(String())
        }
        
        do { // analyzed data
            analyzedDataDictionary = [:]
        }
        
        do { // latest update time
            latestUpdateTime =  CurrentValueSubject(nil)
        }
        
        do {
            anyCancellableSet = Set<AnyCancellable>()
        }
        
        do {
            refresh = CurrentValueSubject(())
        }
        
        super.init(coder: coder)
        
        do { // search controller
            let searchController = UISearchController()
            searchController.searchBar.delegate = self
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        do {
            title = R.string.localizable.analyzedResult()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // latestUpdateTimeItem
        do {
            latestUpdateTime
                .map { latestUpdateTime in latestUpdateTime.map(DateFormatter.uiDateFormatter.string(from:)) }
                .map { latestUpdateTimeString in latestUpdateTimeString ?? "-" }
                .assign(to: \.title, on: latestUpdateTimeItem)
                .store(in: &anyCancellableSet)
            
            latestUpdateTimeItem.isEnabled = false
            latestUpdateTimeItem.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .disabled)
        }
        
        // sort item menu
        do {
            let increasingAction = UIAction(title: Order.increasing.localizedName,
                                                   image: UIImage(systemName: "arrow.up.right"),
                                                   handler: { [unowned self] _ in order.send(.increasing) })
            let decreasingAction =  UIAction(title: Order.decreasing.localizedName,
                                             image: UIImage(systemName: "arrow.down.right"),
                                             handler: { [unowned self] _ in order.send(.decreasing) })
            
            order.first()
                .sink { order in
                    switch order {
                    case .increasing:
                        increasingAction.state = .on
                    case .decreasing:
                        decreasingAction.state = .on
                    }
                }
                .store(in: &anyCancellableSet)
            
            let sortMenu = UIMenu(title: R.string.localizable.sortedBy(),
                                  image: UIImage(systemName: "arrow.up.arrow.down"),
                                  options: .singleSelection,
                                  children: [increasingAction, decreasingAction])
            
            sortItem.menu = UIMenu(title: "",
                                   options: .singleSelection,
                                   children: [sortMenu])
            
            order
                .sink { [unowned self] order in
                    UserDefaults.order = order
                    sortItem.menu?.children.first?.subtitle = order.localizedName
                }
                .store(in: &anyCancellableSet)
        }
        
        // table view
        do {
            refreshControl = UIRefreshControl()
            let handler = UIAction { [unowned self] _ in refresh.send() }
            refreshControl?.addAction(handler, for: .primaryActionTriggered)
            
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currency in
                let reusedIdentifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
                
                guard let data = analyzedDataDictionary[currency] else { return cell }
                
                let deviationString = NumberFormatter.localizedString(from: NSNumber(value: data.deviation), number: .decimal)
                let meanString = NumberFormatter.localizedString(from: NSNumber(value: data.mean), number: .decimal)
                let latestString = NumberFormatter.localizedString(from: NSNumber(value: data.latest), number: .decimal)
                
                cell.textLabel?.text = [currency.code, currency.localizedString, deviationString].joined(separator: ", ")
                cell.textLabel?.adjustsFontForContentSizeCategory = true
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
                cell.textLabel?.textColor = data.deviation < 0 ? .systemGreen : .systemRed
                
                cell.detailTextLabel?.text = R.string.localizable.currencyCellDetail(meanString, latestString)
                cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
                cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
                
                return cell
            }
            dataSource.defaultRowAnimation = .fade
        }
        
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
                    
                    var sortedTuple = analyzedDataDictionary
                        .sorted { lhs, rhs in
                            switch order {
                            case .increasing:
                                return lhs.value.deviation < rhs.value.deviation
                            case .decreasing:
                                return lhs.value.deviation > rhs.value.deviation
                            }
                        }
                    
                    if !(searchText.isEmpty) {
                        sortedTuple = sortedTuple
                            .filter { (currency,_) in
                                [currency.code, currency.localizedString].contains { text in text.lowercased().contains(searchText.lowercased()) }
                            }
                    }
                    
                    let sortedCurrencies = sortedTuple.map { $0.key }
                    var snapshot = Snapshot()
                    snapshot.appendSections([.main])
                    snapshot.appendItems(sortedCurrencies)
                    snapshot.reloadSections([.main])
                    
                    dataSource.apply(snapshot)
                    
                    refreshControl?.endRefreshing()
                }
                .store(in: &anyCancellableSet)
            
        }
    }
    
    @IBSegueAction func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        fatalError("not yet implemented")
//        SettingTableViewController(coder: coder,
//                                   numberOfDay: numberOfDay,
//                                   baseCurrency: baseCurrency) { [unowned self] editedNumberOfDay, editedBaseCurrency in
//            do { // base currency
//                baseCurrency = editedBaseCurrency
//                UserDefaults.baseCurrency = baseCurrency
//            }
//
//            do { // number Of Day
//                numberOfDay = editedNumberOfDay
//                UserDefaults.numberOfDay = numberOfDay
//            }
//
//            refreshDataAndPopulateTableView()
//        }
    }
    
    
    
    private func showErrorAlert(error: Error) {
#warning("這出乎我的意料，要向下轉型才讀得到正確的 localizedDescription，要查一下資料。")
        
        let alertController: UIAlertController
        
        do { // alert controller
            let message: String
            
            if let errorMessage = error as? ResponseDataModel.ServerError {
                message = errorMessage.localizedDescription
            } else {
                message = error.localizedDescription
            }
            
            let alertTitle = R.string.localizable.alertTitle()
            alertController = UIAlertController(title: alertTitle,
                                                message: message,
                                                preferredStyle: .alert)
        }
        
        do { // alert action
            let alertActionTitle = R.string.localizable.alertActionTitle()
            let alertAction = UIAlertAction(title: alertActionTitle, style: .cancel) { _ in
                alertController.dismiss(animated: true)
            }
            alertController.addAction(alertAction)
        }
        
        present(alertController, animated: true)
    }
}

// MARK: - Search Bar Delegate
extension ResultTableViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.searchText.send(searchText)
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchText.send("")
    }
}

// MARK: - name space
private extension ResultTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, Currency>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, Currency>
    
}
// MARK: - name space
extension ResultTableViewController {
    /// 資料的排序方式。
    /// 因為要儲存在 UserDefaults，所以 access control 不能是 private。
    enum Order: String {
        case increasing
        case decreasing
        
        var localizedName: String {
            switch self {
            case .increasing: return R.string.localizable.increasing()
            case .decreasing: return R.string.localizable.decreasing()
            }
        }
        
    }
}
