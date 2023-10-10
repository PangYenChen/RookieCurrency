import UIKit

class BaseResultTableViewController: UITableViewController {
    // MARK: - IBOutlet
    @IBOutlet weak var updatingStatusBarButtonItem: UIBarButtonItem!
    
    @IBOutlet weak var sortingBarButtonItem: UIBarButtonItem!
    
    // MARK: - store properties
    private var dataSource: DataSource!
    
    private let initialOrder: BaseResultModel.Order
    
    // MARK: - life cycle
    required init?(coder: NSCoder, initialOrder: BaseResultModel.Order) {
        self.initialOrder = initialOrder
        
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // refresh control
        do {
            refreshControl = UIRefreshControl()
            let handler = UIAction { [unowned self] _ in requestDataFromModel() }
            refreshControl?.addAction(handler, for: .primaryActionTriggered)
        }
        
        // updatingStatusItem
        do {
            updatingStatusBarButtonItem.isEnabled = false
            updatingStatusBarButtonItem.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .disabled)
        }
        
        // table view data source
        do {
            dataSource = DataSource(tableView: tableView) { tableView, indexPath, analyzedData in
                let reusedIdentifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
                
                var contentConfiguration = cell.defaultContentConfiguration()
                contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                contentConfiguration.textToSecondaryTextVerticalPadding = 4
                
                // text
                do {
                    let deviationString = analyzedData.deviation.formatted()
                    let fluctuationString = R.string.resultScene.fluctuation(deviationString)
                    
                    contentConfiguration.text = [analyzedData.currencyCode,
                                                 Locale.autoupdatingCurrent.localizedString(forCurrencyCode: analyzedData.currencyCode),
                                                 fluctuationString]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    
                    contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
                    contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
                    contentConfiguration.textProperties.color = analyzedData.deviation < 0 ? .systemGreen : .systemRed
                }
                
                // secondary text
                do {
                    let meanString = analyzedData.mean.formatted()
                    let latestString = analyzedData.latest.formatted()
                    
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
            let increasingAction = UIAction(title: BaseResultModel.Order.increasing.localizedName,
                                            image: UIImage(systemName: "arrow.up.right"),
                                            handler: { [unowned self] _ in setOrder(.increasing) })
            let decreasingAction = UIAction(title: BaseResultModel.Order.decreasing.localizedName,
                                            image: UIImage(systemName: "arrow.down.right"),
                                            handler: { [unowned self] _ in setOrder(.decreasing) })
            
            switch initialOrder {
            case .increasing:
                increasingAction.state = .on
            case .decreasing:
                decreasingAction.state = .on
            }
            
            let sortMenu = UIMenu(title: R.string.share.sortedBy(),
                                  image: UIImage(systemName: "arrow.up.arrow.down"),
                                  options: .singleSelection,
                                  children: [increasingAction, decreasingAction])
            
            sortingBarButtonItem.menu = UIMenu(title: "",
                                               options: .singleSelection,
                                               children: [sortMenu])
            
            sortingBarButtonItem.menu?.children.first?.subtitle = initialOrder.localizedName
        }
    }
    
    // MARK: - Hook methods
    func setOrder(_ order: BaseResultModel.Order) {
        fatalError("select(order:) has not been implemented")
    }
    
    func requestDataFromModel() {
        fatalError("refreshControlTriggered()")
    }
    
    @IBSegueAction func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        fatalError("showSetting(_:) has not been implemented")
    }
}

// MARK: - helper methods
extension BaseResultTableViewController {
    final func populateTableViewWith(_ analyzedDataArray: [BaseResultModel.AnalyzedData]) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(analyzedDataArray)
        snapshot.reloadSections([.main])
        
        dataSource.apply(snapshot)
    }
}

// MARK: - Alert Presenter
extension BaseResultTableViewController: AlertPresenter {}

// MARK: - Search Bar Delegate
extension BaseResultTableViewController: UISearchBarDelegate {}

// MARK: - private name space
private extension BaseResultTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, BaseResultModel.AnalyzedData>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, BaseResultModel.AnalyzedData>
}
