import UIKit

class BaseResultTableViewController: UITableViewController {
    
    // MARK: - IBOutlet
    @IBOutlet weak var updatingStatusItem: UIBarButtonItem!
    
    @IBOutlet weak var sortItem: UIBarButtonItem!
    
    /// 分析過的匯率資料
    var analyzedDataDictionary: [ResponseDataModel.CurrencyCode: Analyst.AnalyzedData]
    
    private var dataSource: DataSource!
    
    let autoRefreshTimeInterval: TimeInterval
    
    // MARK: - life cycle
    required init?(coder: NSCoder) {
        
        analyzedDataDictionary = [:]
        
        autoRefreshTimeInterval = 10
        
        super.init(coder: coder)
        
        // search controller
        do {
            let searchController = UISearchController()
            searchController.searchBar.delegate = self
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        // 在 app 內顯示 app icon，以便看出是哪個 target
        do {
            let imageView = UIImageView(image: UIImage(named: "AppIcon"))
            let rightBarButton = UIBarButtonItem(customView: imageView)
            navigationItem.setRightBarButton(rightBarButton, animated: false)
        }
        
        // title
        do {
            title = R.string.resultScene.analyzedResult()
            navigationItem.largeTitleDisplayMode = .automatic
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // refresh control
        do {
            refreshControl = UIRefreshControl()
            let handler = UIAction { [unowned self] _ in refreshControlTriggered() }
            refreshControl?.addAction(handler, for: .primaryActionTriggered)
        }
        
        // updatingStatusItem
        do {
            updatingStatusItem.isEnabled = false
            updatingStatusItem.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .disabled)
        }
        
        // table view data source
        do {
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currencyCode in
                let reusedIdentifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
                
                guard let data = analyzedDataDictionary[currencyCode] else { return cell }
                
                var contentConfiguration = cell.defaultContentConfiguration()
                contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                contentConfiguration.textToSecondaryTextVerticalPadding = 4
                
                // text
                do {
                    let deviationString = data.deviation.formatted()
                    let fluctuationString = R.string.resultScene.fluctuation(deviationString)

                    contentConfiguration.text = [currencyCode,
                                                 Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode),
                                                 fluctuationString]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    
                    contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
                    contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
                    contentConfiguration.textProperties.color = data.deviation < 0 ? .systemGreen : .systemRed
                }
                
                // secondary text
                do {
                    let meanString = data.mean.formatted()
                    let latestString = data.latest.formatted()
                    
                    contentConfiguration.secondaryText = R.string.resultScene.currencyCellDetail(meanString, latestString)
                    contentConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
                    contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
                }
                
                cell.contentConfiguration = contentConfiguration
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
        }
        
        // sort Item
        do {
            let increasingAction = UIAction(title: Order.increasing.localizedName,
                                            image: UIImage(systemName: "arrow.up.right"),
                                            handler: { [unowned self] _ in setOrder(.increasing) })
            let decreasingAction = UIAction(title: Order.decreasing.localizedName,
                                            image: UIImage(systemName: "arrow.down.right"),
                                            handler: { [unowned self] _ in setOrder(.decreasing) })
            
            switch getOrder() {
            case .increasing:
                increasingAction.state = .on
            case .decreasing:
                decreasingAction.state = .on
            }
            
            let sortMenu = UIMenu(title: R.string.share.sortedBy(),
                                  image: UIImage(systemName: "arrow.up.arrow.down"),
                                  options: .singleSelection,
                                  children: [increasingAction, decreasingAction])
            
            sortItem.menu = UIMenu(title: "",
                                   options: .singleSelection,
                                   children: [sortMenu])
        }
    }
    
    // MARK: - method
    
    /// 更新 table view，純粹把資料填入 table view，不動資料。
    final func populateTableView(analyzedDataDictionary: [ResponseDataModel.CurrencyCode: Analyst.AnalyzedData],
                                 order: Order,
                                 searchText: String) {
        var sortedTuple = analyzedDataDictionary
            .sorted { lhs, rhs in
                switch order {
                case .increasing:
                    return lhs.value.deviation < rhs.value.deviation
                case .decreasing:
                    return lhs.value.deviation > rhs.value.deviation
                }
            }
        
        if !searchText.isEmpty { // filtering if needed
            sortedTuple = sortedTuple
                .filter { (currencyCode,_) in
                    [currencyCode, Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)]
                        .compactMap { $0 }
                        .contains { text in text.localizedStandardContains(searchText) }
                }
        }
        
        let sortedCurrencies = sortedTuple.map { $0.key }
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(sortedCurrencies)
        snapshot.reloadSections([.main])
        
        dataSource.apply(snapshot)
    }
    
    // MARK: - Hook methods
    func setOrder(_ order: Order) {
        fatalError("select(order:) has not been implemented")
    }
    
    func getOrder() -> Order {
        fatalError("getOrder() has not been implemented")
    }
    
    func refreshControlTriggered() {
        fatalError("refreshControlTriggered()")
    }
    
    @IBSegueAction func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        fatalError("showSetting(_:) has not been implemented")
    }
}

// MARK: - Alert Presenter
extension BaseResultTableViewController: AlertPresenter {}

// MARK: - Search Bar Delegate
extension BaseResultTableViewController: UISearchBarDelegate {}

// MARK: - name space
extension BaseResultTableViewController {
    /// 資料的排序方式。
    /// 因為要儲存在 UserDefaults，所以 access control 不能是 private。
    enum Order: String {
        case increasing
        case decreasing
        
        var localizedName: String {
            switch self {
            case .increasing: return R.string.resultScene.increasing()
            case .decreasing: return R.string.resultScene.decreasing()
            }
        }
    }
    
    typealias UserSetting = (numberOfDay: Int, baseCurrency: ResponseDataModel.CurrencyCode, currencyOfInterest: Set<ResponseDataModel.CurrencyCode>)
}

// MARK: - private name space
private extension BaseResultTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
}
