import UIKit

/// 這裡的 base 是 base class 的意思，不是基準貨幣
class BaseCurrencySelectionTableViewController: UITableViewController {
    
    // MARK: - property
    @IBOutlet var sortBarButtonItem: UIBarButtonItem!
    
    let currencySelectionModel: CurrencySelectionModelProtocol
    
    private var dataSource: DataSource!
    
    // MARK: - life cycle
    init?(coder: NSCoder, currencySelectionModel: CurrencySelectionModelProtocol) {
        
        self.currencySelectionModel = currencySelectionModel
        
        super.init(coder: coder)
        
        do {
            let searchController = UISearchController()
            navigationItem.searchController = searchController
            searchController.searchBar.delegate = self
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        
        title = currencySelectionModel.title
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.allowsMultipleSelection = currencySelectionModel.allowsMultipleSelection
        
        // table view data source and delegate
        do {
            dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, currencyCode in
                let identifier = R.reuseIdentifier.currencyCell.identifier
                let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
                
                cell.automaticallyUpdatesContentConfiguration = true
                cell.configurationUpdateHandler = { [unowned self] cell, state in
                    var contentConfiguration = cell.defaultContentConfiguration()
                    
                    // content
                    do {
                        let localizedCurrencyDescription = Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode)
                        
                        let serverCurrencyDescription = currencySelectionModel.currencyCodeDescriptionDictionary[currencyCode]
                        
                        let currencyDescription = localizedCurrencyDescription ?? serverCurrencyDescription
                        
                        switch currencySelectionModel.getSortingMethod() {
                        case .currencyName, .currencyNameZhuyin:
                            contentConfiguration.text = currencyDescription
                            contentConfiguration.secondaryText = currencyCode
                        case .currencyCode:
                            contentConfiguration.text = currencyCode
                            contentConfiguration.secondaryText = currencyDescription
                        }
                    }
                    
                    // font
                    do {
                        contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .headline)
                        contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
                        
                        contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
                        contentConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
                    }
                    
                    // other
                    do {
                        contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
                        contentConfiguration.textToSecondaryTextVerticalPadding = 4
                    }
                    
                    cell.contentConfiguration = contentConfiguration
                    cell.accessoryType = state.isSelected ? .checkmark : .none
                }
                
                return cell
            }
            
            dataSource.defaultRowAnimation = .fade
        }
        
        // sort bar button item
        do {
            
            let currencyNameMenu: UIMenu
            
            let ascendingAction: UIAction
            
            do {
                ascendingAction = UIAction(title: SortingOrder.ascending.localizedName,
                                           image: UIImage(systemSymbol: .arrowUpRight),
                                           state: .on,
                                           handler: { [unowned self] _ in set(sortingMethod: .currencyName, sortingOrder: .ascending) })
                
                let descendingAction = UIAction(title: SortingOrder.descending.localizedName,
                                                image: UIImage(systemSymbol: .arrowDownRight),
                                                handler: { [unowned self] _ in set(sortingMethod: .currencyName, sortingOrder: .descending) })
                
                currencyNameMenu = UIMenu(title: SortingMethod.currencyName.localizedName,
                                          children: [ascendingAction, descendingAction])
            }
            
            let currencyCodeMenu: UIMenu
            do {
                let ascendingAction = UIAction(title: SortingOrder.ascending.localizedName,
                                               image: UIImage(systemSymbol: .arrowUpRight),
                                               handler: { [unowned self] _ in set(sortingMethod: .currencyCode, sortingOrder: .ascending) })
                
                let descendingAction = UIAction(title: SortingOrder.descending.localizedName,
                                                image: UIImage(systemSymbol: .arrowDownRight),
                                                handler: { [unowned self] _ in set(sortingMethod: .currencyCode, sortingOrder: .descending) })
                
                currencyCodeMenu = UIMenu(title: SortingMethod.currencyCode.localizedName,
                                          children: [ascendingAction, descendingAction])
            }
            
            var children = [currencyNameMenu, currencyCodeMenu]
            
            // 注音
            if Bundle.main.preferredLocalizations.first == "zh-Hant" {
                let ascendingAction = UIAction(title: SortingOrder.ascending.localizedName,
                                               image: UIImage(systemSymbol: .arrowUpRight),
                                               handler: { [unowned self] _ in set(sortingMethod: .currencyNameZhuyin, sortingOrder: .ascending) })
                
                let descendingAction = UIAction(title: SortingOrder.descending.localizedName,
                                                image: UIImage(systemSymbol: .arrowDownRight),
                                                handler: { [unowned self] _ in set(sortingMethod: .currencyNameZhuyin, sortingOrder: .descending) })
                
                let currencyZhuyinMenu = UIMenu(title: SortingMethod.currencyNameZhuyin.localizedName,
                                                children: [ascendingAction, descendingAction])
                
                children.append(currencyZhuyinMenu)
            }
            
            let sortMenu = UIMenu(title: R.string.share.sortedBy(),
                                  image: UIImage(systemSymbol: .arrowUpArrowDown),
                                  options: .singleSelection,
                                  children: children)
            
            sortBarButtonItem.menu = UIMenu(title: "",
                                            options: .singleSelection,
                                            children: [sortMenu])
            
            // set up the initial state
            do {
                ascendingAction.state = .on
                // action state 的初始值只能在這裡設定，但不能用程式模擬使用者點擊 action，為了確保初始值一致，必須在這裡設定一次 sorting method 跟 sorting order
                set(sortingMethod: .currencyName, sortingOrder: .ascending)
            }
        }
        
        // table view refresh controller
        do {
            tableView.refreshControl = UIRefreshControl()
            
            let action = UIAction { [unowned self] _ in currencySelectionModel.fetch() }
            tableView.refreshControl?.addAction(action, for: .primaryActionTriggered)
            
            tableView.refreshControl?.beginRefreshing()
            tableView.refreshControl?.sendActions(for: .primaryActionTriggered)
        }
    }
    
    // MARK: - Hook methods
    func set(sortingMethod: SortingMethod, sortingOrder: SortingOrder) {
        fatalError("set(sortingMethod:sortingOrder:) has not been implemented")
    }
}

// MARK: - helper method
extension BaseCurrencySelectionTableViewController {
//    final func convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: [ResponseDataModel.CurrencyCode: String],
//                                                sortingMethod: SortingMethod,
//                                                sortingOrder: SortingOrder,
//                                                searchText: String,
//                                                isFirstTimePopulate: Bool) {
//        var snapshot = Snapshot()
//        snapshot.appendSections([.main])
//          
//        let filteredCurrencyCode = currencySelectionModel
//            .convertDataThenPopulateTableView(currencyCodeDescriptionDictionary: currencyCodeDescriptionDictionary,
//                                              sortingMethod: sortingMethod,
//                                              sortingOrder: sortingOrder,
//                                              searchText: searchText)
//        
//        snapshot.appendItems(filteredCurrencyCode)
//        snapshot.reloadSections([.main])
//        
//        DispatchQueue.main.async { [weak self] in
//            
//            self?.dataSource.apply(snapshot) { [weak self] in
//                guard let self else { return }
//                
//                let selectedIndexPath = currencySelectionModel.selectedCurrencyCode
//                    .compactMap { [weak self] selectedCurrencyCode in self?.dataSource.indexPath(for: selectedCurrencyCode) }
//                
//                selectedIndexPath
//                    .forEach { [weak self] indexPath in self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none) }
//                
//                // scroll to first selected index path when first time receiving data
//                if isFirstTimePopulate {
//                    
//                    if let firstSelectedIndexPath = selectedIndexPath.min() {
//                        tableView.scrollToRow(at: firstSelectedIndexPath, at: .top, animated: true)
//                    }
//                    else {
//                        presentAlert(message: R.string.currencyScene.currencyNotSupported())
//                    }
//                }
//            }
//        }
//    }
    
    final func populateTableViewWith(_ array: [ResponseDataModel.CurrencyCode], shouldScrollToFirstSelectedItem: Bool) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        
        snapshot.appendItems(array)
        snapshot.reloadSections([.main])
        
        DispatchQueue.main.async { [weak self] in
            
            self?.dataSource.apply(snapshot) { [weak self] in
                guard let self else { return }
                
                let selectedIndexPath = currencySelectionModel.selectedCurrencyCode
                    .compactMap { [weak self] selectedCurrencyCode in self?.dataSource.indexPath(for: selectedCurrencyCode) }
                
                selectedIndexPath
                    .forEach { [weak self] indexPath in self?.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none) }
                
                    // scroll to first selected index path when first time receiving data
                if shouldScrollToFirstSelectedItem {
                    
                    if let firstSelectedIndexPath = selectedIndexPath.min() {
                        tableView.scrollToRow(at: firstSelectedIndexPath, at: .top, animated: true)
                    }
                    else {
                        presentAlert(message: R.string.currencyScene.currencyNotSupported())
                    }
                }
            }
        }
    }
}

// MARK: - table view delegate relative
extension BaseCurrencySelectionTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let selectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
            assertionFailure("###, \(self), \(#function), 選到的 item 不在 data source 中，這不可能發生。")
            return
        }
        
        currencySelectionModel.select(currencyCode: selectedCurrencyCode)
    }
    
    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        guard let deselectedCurrencyCode = dataSource.itemIdentifier(for: indexPath) else {
            assertionFailure("###, \(self), \(#function), 取消選取的 item 不在 data source 中，這不可能發生。")
            return
        }
        currencySelectionModel.deselect(currencyCode: deselectedCurrencyCode)
    }
}

// MARK: - Search Bar Delegate
extension BaseCurrencySelectionTableViewController: UISearchBarDelegate {}

// MARK: - private name space
extension BaseCurrencySelectionTableViewController {
    enum Section {
        case main
    }
    
    typealias DataSource = UITableViewDiffableDataSource<Section, ResponseDataModel.CurrencyCode>
    typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ResponseDataModel.CurrencyCode>
    
}

// MARK: - Alert Presenter
extension BaseCurrencySelectionTableViewController: AlertPresenter {}
