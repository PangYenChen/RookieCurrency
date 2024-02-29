import UIKit

class BaseResultTableViewController: UITableViewController {
    // MARK: - initializer
    init?(coder: NSCoder, baseResultModel: BaseResultModel) {
        self.baseResultModel = baseResultModel
        
        super.init(coder: coder)
        
        do /*configure search controller*/ {
            let searchController: UISearchController = UISearchController()
            searchController.searchBar.delegate = self
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        do /*show the app icon in app in order to distinguish the target quickly*/ {
            let imageView: UIImageView = UIImageView(image: UIImage(named: "AppIcon"))
            let rightBarButton: UIBarButtonItem = UIBarButtonItem(customView: imageView)
            navigationItem.setRightBarButton(rightBarButton, animated: false)
        }
        
        do /*configure title*/ {
            title = R.string.resultScene.analyzedResult()
            navigationItem.largeTitleDisplayMode = .automatic
        }
    }
    
    // Adding `@available(*, unavailable)` to an initial view controller of a storyboard makes system execute this initializer,
    // which I think is a bug. Therefore, we have to disable `unavailable_function` rule.
    // swiftlint:disable:next unavailable_function
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do /*configure refresh control*/ {
            refreshControl = UIRefreshControl()
            let handler: UIAction = UIAction { [unowned self] _ in baseResultModel.refresh() }
            refreshControl?.addAction(handler, for: .primaryActionTriggered)
        }
        
        do /*configure table view's data source*/ {
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, analyzedData in
                let reusedIdentifier: String = R.reuseIdentifier.currencyCell.identifier
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
                
                var contentConfiguration: UIListContentConfiguration = cell.defaultContentConfiguration()
                contentConfiguration.directionalLayoutMargins = UIConfiguration.TableView.cellContentDirectionalLayoutMargins
                contentConfiguration.textToSecondaryTextVerticalPadding = UIConfiguration.TableView.cellContentTextToSecondaryTextVerticalPadding
                
                do /*configure text*/ {
                    let deviationString: String = analyzedData.deviation.formatted()
                    let fluctuationString: String = R.string.resultScene.fluctuation(deviationString)
                    
                    contentConfiguration.text = [analyzedData.currencyCode,
                                                 baseResultModel.localizedStringFor(currencyCode: analyzedData.currencyCode),
                                                 fluctuationString]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    
                    contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
                    contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
                    contentConfiguration.textProperties.color = analyzedData.deviation < 0 ? .systemGreen : .systemRed
                }
                
                do /*configure secondary text*/ {
                    let meanString: String = analyzedData.mean.formatted()
                    let latestString: String = analyzedData.latest.formatted()
                    
                    contentConfiguration.secondaryText = R.string.resultScene.currencyCellDetail(meanString, latestString)
                    contentConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
                    contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
                }
                
                cell.contentConfiguration = contentConfiguration
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
        }
        
        do /*configure sort item*/ {
            let increasingAction: UIAction = UIAction(
                title: BaseResultModel.Order.increasing.localizedName,
                image: UIImage(systemSymbol: .arrowUpRight)
            ) { [unowned self] _ in setOrder(.increasing) }
            
            let decreasingAction: UIAction = UIAction(
                title: BaseResultModel.Order.decreasing.localizedName,
                image: UIImage(systemSymbol: .arrowDownRight)
            ) { [unowned self] _ in setOrder(.decreasing) }
            
            switch baseResultModel.initialOrder {
                case .increasing: increasingAction.state = .on
                case .decreasing: decreasingAction.state = .on
            }
            
            let sortMenu: UIMenu = UIMenu(title: R.string.share.sortedBy(),
                                          image: UIImage(systemSymbol: .arrowUpArrowDown),
                                          options: .singleSelection,
                                          children: [increasingAction, decreasingAction])
            
            sortingBarButtonItem.menu = UIMenu(title: "",
                                               options: .singleSelection,
                                               children: [sortMenu])
            
            sortingBarButtonItem.menu?.children.first?.subtitle = baseResultModel.initialOrder.localizedName
        }
        
        do /*configure refreshStatusItem*/ {
            refreshStatusBarButtonItem.isEnabled = false
            refreshStatusBarButtonItem.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .disabled)
        }
    }
    
    // MARK: - store properties
    @ViewLoading private var dataSource: DataSource
    
    private let baseResultModel: BaseResultModel
    
    // MARK: - view
    @ViewLoading @IBOutlet private var refreshStatusBarButtonItem: UIBarButtonItem
    
    @ViewLoading @IBOutlet private var sortingBarButtonItem: UIBarButtonItem
    
    // MARK: - kind of abstract method
    // 這樣做的原因是想把兩個 target 共用的 code（設定 `UIAction`）寫在一起。
    // 而內容使用到的 model 的 method 的方式不同，所以無法共用。
    // swiftlint:disable:next unavailable_function
    func setOrder(_ order: BaseResultModel.Order) { fatalError("setOrder() has not been implemented") }
}

// MARK: - segue action
private extension BaseResultTableViewController {
    @IBSegueAction final func showSetting(_ coder: NSCoder) -> SettingTableViewController? {
        SettingTableViewController(coder: coder, model: baseResultModel.makeSettingModel())
    }
}

// MARK: - instance methods
extension BaseResultTableViewController {
    final func populateTableViewWith(_ analyzedDataArray: [BaseResultModel.AnalyzedData]) {
        var snapshot: Snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(analyzedDataArray)
        snapshot.reloadSections([.main])
        
        dataSource.apply(snapshot)
    }
    
    final func populateRefreshStatusBarButtonItemWith(status: BaseResultModel.RefreshStatus) {
        switch status {
            case .process:
                refreshStatusBarButtonItem.title = R.string.resultScene.refreshing()
            case .idle(let latestUpdateTimestamp):
                if tableView.refreshControl?.isRefreshing == true {
                    tableView.refreshControl?.endRefreshing()
                }
                
                let relativeDateString: String = latestUpdateTimestamp.map(Double.init)
                    .map(Date.init(timeIntervalSince1970:))?
                    .formatted(.relative(presentation: .named)) ?? "-"
                refreshStatusBarButtonItem.title = R.string.resultScene.latestUpdateTime(relativeDateString)
        }
    }
    
    final func presentErrorAlert(error: Error) {
        if let presentingViewController {
            if presentingViewController is UIAlertController {
                dismiss(animated: true) { [unowned self] in presentAlert(error: error) }
            }
        }
        else {
            presentAlert(error: error)
        }
    }
}

// MARK: - Alert Presenter
extension BaseResultTableViewController: AlertPresenter {}

// MARK: - Search Bar Delegate
extension BaseResultTableViewController: UISearchBarDelegate {}

// MARK: - private name space
private extension BaseResultTableViewController {
    typealias DataSource = UITableViewDiffableDataSource<Section, BaseResultModel.AnalyzedData>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, BaseResultModel.AnalyzedData>
    
    enum Section {
        case main
    }
}
