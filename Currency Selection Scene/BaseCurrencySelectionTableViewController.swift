import UIKit

/// 這裡的 base 是 base class 的意思，不是基準貨幣
class BaseCurrencySelectionTableViewController: UITableViewController {
    // MARK: - initializer
    init?(coder: NSCoder, baseCurrencySelectionModel: BaseCurrencySelectionModelProtocol) {
        self.baseCurrencySelectionModel = baseCurrencySelectionModel
        
        isFirstTimePopulateTableView = true
        
        super.init(coder: coder)
        
        do {
            let searchController: UISearchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        title = baseCurrencySelectionModel.title
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelection = baseCurrencySelectionModel.allowsMultipleSelection
        
        do /*configure table view's data source*/ {
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currencyCode in
                let reuseIdentifier: String = R.reuseIdentifier.currencyCell.identifier
                let cell: UITableViewCell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
                
                cell.automaticallyUpdatesContentConfiguration = true
                cell.configurationUpdateHandler = { [unowned self] cell, state in
                    var contentConfiguration: UIListContentConfiguration = cell.defaultContentConfiguration()
                    
                    do /*configure content*/ {
                        switch baseCurrencySelectionModel.getSortingMethod() {
                            case .currencyName, .currencyNameZhuyin:
                                contentConfiguration.text = baseCurrencySelectionModel.localizedStringFor(currencyCode: currencyCode)
                                contentConfiguration.secondaryText = currencyCode
                            case .currencyCode:
                                contentConfiguration.text = currencyCode
                                contentConfiguration.secondaryText = baseCurrencySelectionModel.localizedStringFor(currencyCode: currencyCode)
                        }
                    }
                    
                    do /*configure font*/ {
                        contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
                        contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
                        
                        contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
                        contentConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
                    }
                    
                    do /*other*/ {
                        contentConfiguration.directionalLayoutMargins = UIConfiguration.TableView.cellContentDirectionalLayoutMargins
                        contentConfiguration.textToSecondaryTextVerticalPadding = UIConfiguration.TableView.cellContentTextToSecondaryTextVerticalPadding
                    }
                    
                    cell.contentConfiguration = contentConfiguration
                    cell.accessoryType = state.isSelected ? .checkmark : .none
                }
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
        }
        
        do /*configure sort bar button item*/ {
            let currencyNameMenu: UIMenu
            do /*initialize currency name menu*/ {
                let ascendingAction: UIAction = UIAction(
                    title: CurrencySelectionModel.SortingOrder.ascending.localizedName,
                    image: UIImage(systemSymbol: .arrowUpRight)
                ) { [unowned self] _ in set(sortingMethod: .currencyName, sortingOrder: .ascending) }
                
                let descendingAction: UIAction = UIAction(
                    title: CurrencySelectionModel.SortingOrder.descending.localizedName,
                    image: UIImage(systemSymbol: .arrowDownRight)
                ) { [unowned self] _ in set(sortingMethod: .currencyName, sortingOrder: .descending) }
                
                currencyNameMenu = UIMenu(title: CurrencySelectionModel.SortingMethod.currencyName.localizedName,
                                          children: [ascendingAction, descendingAction])
            }
            
            let currencyCodeMenu: UIMenu
            do /*initialize currency code menu*/ {
                let ascendingAction: UIAction = UIAction(
                    title: CurrencySelectionModel.SortingOrder.ascending.localizedName,
                    image: UIImage(systemSymbol: .arrowUpRight)
                ) { [unowned self] _ in set(sortingMethod: .currencyCode, sortingOrder: .ascending) }
                
                let descendingAction: UIAction = UIAction(
                    title: CurrencySelectionModel.SortingOrder.descending.localizedName,
                    image: UIImage(systemSymbol: .arrowDownRight)
                ) { [unowned self] _ in set(sortingMethod: .currencyCode, sortingOrder: .descending) }
                
                currencyCodeMenu = UIMenu(title: CurrencySelectionModel.SortingMethod.currencyCode.localizedName,
                                          children: [ascendingAction, descendingAction])
            }
            
            var sortMenuChildren: [UIMenu] = [currencyNameMenu, currencyCodeMenu]
            
            // 注音
            if Bundle.main.preferredLocalizations.first == "zh-Hant" {
                let ascendingAction: UIAction = UIAction(
                    title: CurrencySelectionModel.SortingOrder.ascending.localizedName,
                    image: UIImage(systemSymbol: .arrowUpRight)
                    ) { [unowned self] _ in set(sortingMethod: .currencyNameZhuyin, sortingOrder: .ascending) }
                
                let descendingAction: UIAction = UIAction(
                    title: CurrencySelectionModel.SortingOrder.descending.localizedName,
                    image: UIImage(systemSymbol: .arrowDownRight)
                ) { [unowned self] _ in set(sortingMethod: .currencyNameZhuyin, sortingOrder: .descending) }
                
                let currencyZhuyinMenu: UIMenu = UIMenu(title: CurrencySelectionModel.SortingMethod.currencyNameZhuyin.localizedName,
                                                        children: [ascendingAction, descendingAction])
                
                sortMenuChildren.append(currencyZhuyinMenu)
            }
            
            do /*configure initial state*/ {
                let sortingMethodIndex: Int = switch baseCurrencySelectionModel.getSortingMethod() {
                    case .currencyName: 0
                    case .currencyCode: 1
                    case .currencyNameZhuyin: 2
                }
                
                let sortingOrderIndex: Int = switch baseCurrencySelectionModel.initialSortingOrder {
                    case .ascending: 0
                    case .descending: 1
                }
                
                let initialChild: UIMenu = sortMenuChildren[sortingMethodIndex]
                (initialChild.children[sortingOrderIndex] as? UIAction)?.state = .on
                
                updateSortingLocalizedStringFor(method: baseCurrencySelectionModel.getSortingMethod(),
                                                andOrder: baseCurrencySelectionModel.initialSortingOrder)
            }
            
            let sortMenu: UIMenu = UIMenu(title: R.string.share.sortedBy(),
                                          image: UIImage(systemSymbol: .arrowUpArrowDown),
                                          options: .singleSelection,
                                          children: sortMenuChildren)
            
            sortBarButtonItem.menu = UIMenu(title: "",
                                            options: .singleSelection,
                                            children: [sortMenu])
        }
        
        do /*initialize table view refresh control*/ {
            tableView.refreshControl = UIRefreshControl()
            
            let action: UIAction = UIAction { [unowned self] _ in baseCurrencySelectionModel.update() }
            tableView.refreshControl?.addAction(action, for: .primaryActionTriggered)
            
            tableView.refreshControl?.beginRefreshing()
            tableView.refreshControl?.sendActions(for: .primaryActionTriggered)
        }
    }
    
    private let baseCurrencySelectionModel: BaseCurrencySelectionModelProtocol
    
    private var isFirstTimePopulateTableView: Bool
    
    @ViewLoading private var dataSource: DataSource
    
    @ViewLoading @IBOutlet private var sortBarButtonItem: UIBarButtonItem
}

// MARK: - helper method
extension BaseCurrencySelectionTableViewController {
    final func set(
        sortingMethod: CurrencySelectionModel.SortingMethod,
        sortingOrder: CurrencySelectionModel.SortingOrder
    ) {
        updateSortingLocalizedStringFor(method: sortingMethod, andOrder: sortingOrder)
        
        baseCurrencySelectionModel.set(sortingMethod: sortingMethod, andOrder: sortingOrder)
    }
    
    final func updateUIFor(result: Result<[ResponseDataModel.CurrencyCode], Error>) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            tableView.refreshControl?.endRefreshing()
            
            switch result {
                case .success(let currencyCodeArray):
                    var snapshot: Snapshot = Snapshot()
                    snapshot.appendSections([.main])
                    
                    snapshot.appendItems(currencyCodeArray)
                    snapshot.reloadSections([.main]) // TODO: 查一下當初為什麼要 reload
                    
                    dataSource.apply(snapshot) { [weak self] in
                        guard let self else { return }
                        
                        let selectedIndexPaths: [IndexPath] = currencyCodeArray
                            .filter(baseCurrencySelectionModel.isCurrencyCodeSelected(_:))
                            .compactMap(dataSource.indexPath(for:))
                        
                        selectedIndexPaths
                            .forEach { [weak self] indexPath in self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none) }
                        
                        // scroll to first selected index path when first time receiving data
                        if isFirstTimePopulateTableView {
                            if let firstSelectedIndexPath = selectedIndexPaths.min() {
                                tableView.scrollToRow(at: firstSelectedIndexPath, at: .top, animated: true)
                            }
                            else {
                                presentAlert(message: R.string.currencyScene.currencyNotSupported())
                            }
                            isFirstTimePopulateTableView = false
                        }
                    }
                    
                case .failure(let failure):
                    presentAlert(error: failure)
            }
        }
    }
}

// MARK: - private method
private extension BaseCurrencySelectionTableViewController {
    final func updateSortingLocalizedStringFor(
        method sortingMethod: CurrencySelectionModel.SortingMethod,
        andOrder sortingOrder: CurrencySelectionModel.SortingOrder
    ) {
        sortBarButtonItem.menu?.children.first?.subtitle = R.string.currencyScene.sortingWay(sortingMethod.localizedName,
                                                                                             sortingOrder.localizedName)
    }
}

// MARK: - table view delegate relative
extension BaseCurrencySelectionTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
            assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
            return
        }
        
        baseCurrencySelectionModel.select(currencyCode: selectedCurrencyCode)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let deselectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
            assertionFailure("###, \(self), \(#function), 取消選取的 item 不在 data source 中，這不可能發生。")
            return
        }
        
        baseCurrencySelectionModel.deselect(currencyCode: deselectedCurrencyCode)
    }
}

// MARK: - Search Bar Delegate
extension BaseCurrencySelectionTableViewController: UISearchBarDelegate { // TODO: 兩個 target 分開寫
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        baseCurrencySelectionModel.set(searchText: searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        baseCurrencySelectionModel.set(searchText: nil)
    }
}

// MARK: - name space
extension BaseCurrencySelectionTableViewController {
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>

    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
    enum Section {
        case main
    }
}

// MARK: - Alert Presenter
extension BaseCurrencySelectionTableViewController: AlertPresenter {}
