import UIKit

class BaseResultTableViewController: UITableViewController {
    // MARK: - initializer
    init?(coder: NSCoder, baseResultModel: BaseResultModel) {
        self.baseResultModel = baseResultModel
        
        hasReceivedResult = false
        
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
            title = R.string.resultScene.analysisResult()
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
            dataSource = DataSource(tableView: tableView) { tableView, indexPath, rateStatistic in
                let reusedIdentifier: String = R.reuseIdentifier.currencyCell.identifier
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: reusedIdentifier, for: indexPath)
                
                var contentConfiguration: UIListContentConfiguration = cell.defaultContentConfiguration()
                contentConfiguration.directionalLayoutMargins = UIConfiguration.TableView.cellContentDirectionalLayoutMargins
                contentConfiguration.textToSecondaryTextVerticalPadding = UIConfiguration.TableView.cellContentTextToSecondaryTextVerticalPadding
                
                do /*configure text*/ {
                    let deviationString: String = rateStatistic.fluctuation.formatted()
                    let fluctuationString: String = R.string.resultScene.fluctuation(deviationString)
                    
                    contentConfiguration.text = [rateStatistic.currencyCode,
                                                 rateStatistic.localizedString,
                                                 fluctuationString]
                        .compactMap { $0 }
                        .joined(separator: ", ")
                    
                    contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
                    contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
                    contentConfiguration.textProperties.color = rateStatistic.fluctuation < 0 ? .systemGreen : .systemRed
                }
                
                do /*configure secondary text*/ {
                    let meanString: String = rateStatistic.meanRate.formatted()
                    let latestString: String = rateStatistic.latestRate.formatted()
                    
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
                title: BaseResultModel.Order.increasing.localizedString,
                image: UIImage(systemSymbol: .arrowUpRight)
            ) { [unowned self] _ in setOrder(.increasing) }
            
            let decreasingAction: UIAction = UIAction(
                title: BaseResultModel.Order.decreasing.localizedString,
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
            
            sortingBarButtonItem.menu?.children.first?.subtitle = baseResultModel.initialOrder.localizedString
        }
        
        do /*configure refreshStatusItem*/ {
            refreshStatusBarButtonItem.isEnabled = false
            refreshStatusBarButtonItem.setTitleTextAttributes([.foregroundColor: UIColor.label], for: .disabled)
        }
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        hasReceivedResult ? () : refreshControl?.beginRefreshing()
    }
    
    // MARK: - store properties
    @ViewLoading private var dataSource: DataSource
    
    private let baseResultModel: BaseResultModel
    
    private var hasReceivedResult: Bool
    
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
    final func populateTableViewWith(_ rateStatistics: [BaseResultModel.RateStatistic]) {
        hasReceivedResult = true
        
        var snapshot: Snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(rateStatistics)
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
    
    final func presentDataAbsentAlertFor(currencyCodeSet: Set<ResponseDataModel.CurrencyCode>) {
        hasReceivedResult = true
        
        let currencyCodeDescriptions: [String] = currencyCodeSet
            .map(baseResultModel.localizedStringFor(currencyCode:))
            .sorted()
        
        let listedCurrencyCodeDescriptions: String = ListFormatter.localizedString(byJoining: currencyCodeDescriptions)
        
        let message: String = R.string.resultScene.dataAbsent(listedCurrencyCodeDescriptions)
        
        if let presentingViewController {
            if presentingViewController is UIAlertController {
                dismiss(animated: true) { [unowned self] in presentAlert(message: message) }
            }
        }
        else {
            presentAlert(message: message)
        }
    }
    
    final func presentErrorAlert(error: Error) {
        hasReceivedResult = true
        
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
    typealias DataSource = UITableViewDiffableDataSource<Section, QuasiBaseResultModel.RateStatistic>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, QuasiBaseResultModel.RateStatistic>
    
    enum Section {
        case main
    }
}
