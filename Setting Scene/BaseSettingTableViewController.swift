import UIKit

class BaseSettingTableViewController: UITableViewController, AlertPresenter {
    // MARK: - properties
    var editedNumberOfDays: Int
    
    var editedBaseCurrencyCode: ResponseDataModel.CurrencyCode
    
    var editedCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
    
    var hasChangesToSave: Bool
    
    // MARK: UI objects
    @IBOutlet var saveButton: UIBarButtonItem!
    
    @IBOutlet private var sectionFooterView: UIView!
    
    let stepper: UIStepper
    
    @IBOutlet private var versionLabel: UILabel!
    
    @IBOutlet private var dateLabel: UILabel!
    
    // MARK: - private property
    
    private let baseSettingModel: BaseSettingModel
    
    // MARK: - methods
    init?(coder: NSCoder, baseSettingModel: BaseSettingModel) {
        
        editedNumberOfDays = -1
        
        editedBaseCurrencyCode = ""
        
        editedCurrencyCodeOfInterest = Set<ResponseDataModel.CurrencyCode>()
        
        hasChangesToSave = false
        
        stepper = UIStepper()
        
        self.baseSettingModel = baseSettingModel
        
        super.init(coder: coder)
        
        // stepper
        do {
            let handler = UIAction { [unowned self] _ in stepperValueDidChange() }
            stepper.addAction(handler, for: .primaryActionTriggered)
        }
        
        title = R.string.settingScene.setting()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            versionLabel.font = UIFont.preferredFont(forTextStyle: .callout)
            versionLabel.textColor = UIColor.secondaryLabel
            versionLabel.adjustsFontForContentSizeCategory = true
            let appVersionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            versionLabel.text = R.string.settingScene.version(appVersionString ?? "", AppUtility.gitHash)
        }
        
        do {
            dateLabel.font = UIFont.preferredFont(forTextStyle: .callout)
            dateLabel.textColor = UIColor.secondaryLabel
            dateLabel.adjustsFontForContentSizeCategory = true
            let commitDate = Date(timeIntervalSince1970: Double(AppUtility.commitTimestamp))
            let dateString = commitDate.formatted(date: .numeric, time: .complete)
            
            dateLabel.text = R.string.settingScene.versionDate(dateString)
        }
    }
    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        
//        let baseCurrencyIndexPath = IndexPath(row: Row.baseCurrency.rawValue, section: 0)
//        let currencyOfInterestIndexPath = IndexPath(row: Row.currencyOfInterest.rawValue, section: 0)
//        DispatchQueue.main.async { [unowned self] in
//            tableView.reloadRows(at: [baseCurrencyIndexPath, currencyOfInterestIndexPath], with: .automatic)
//        }
//    }
    // TODO: 要確認從下一頁回來沒問題
    
    // MARK: - hook methods
    func stepperValueDidChange() {
        fatalError("stepperValueDidChange() has not been implemented")
    }
    
    // MARK: - Navigation
    @IBSegueAction func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        fatalError("showBaseCurrencyTableViewController(_:) has not been implemented")
    }
    @IBSegueAction func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        fatalError("showCurrencyOfInterestTableViewController(_:) has not been implemented")
    }
}

// MARK: - internal method
extension BaseSettingTableViewController {
    @IBAction final func didTapCancelButton(_ sender: UIBarButtonItem) {
        hasChangesToSave ? presentDismissalConfirmation(withSaveOption: false) : cancel()
    }
    
    @IBAction final func save() {
        baseSettingModel.save()
        dismiss(animated: true)
    }
    
    final func cancel() {
        baseSettingModel.cancel()
        dismiss(animated: true)
    }
    
    final func presentDismissalConfirmation(withSaveOption: Bool) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        // 儲存的 action，只有在下拉的時候加上這個 action。
        if withSaveOption {
            let title = R.string.settingScene.cancelAlertSavingTitle()
            let saveAction = UIAlertAction(title: title,
                                           style: .default) { [unowned self] _ in save() }
            alertController.addAction(saveAction)
        }
        
        // 捨棄變更的 action
        do {
            let title = R.string.settingScene.cancelAlertDiscardTitle()
            let discardChangeAction = UIAlertAction(title: title,
                                                    style: .default) { [unowned self] _ in cancel() }
            
            alertController.addAction(discardChangeAction)
        }
        
        // 繼續編輯的 action
        do {
            let title = R.string.settingScene.cancelAlertContinueTitle()
            let continueSettingAction = UIAlertAction(title: title, style: .cancel)
            
            alertController.addAction(continueSettingAction)
        }
        
        present(alertController, animated: true)
    }
    
    final func updateNumberOfDaysRow(for numberOfDays: Int) {
        let numberOfDayRow = IndexPath(row: Row.numberOfDay.rawValue, section: 0)
        
        guard let cell = tableView.cellForRow(at: numberOfDayRow) else {
            assertionFailure("###, \(#function), \(self), 拿不到設定 number of day 的 cell。")
            return
        }
        
        guard var contentConfiguration = cell.contentConfiguration as? UIListContentConfiguration else {
            assertionFailure("###, \(#function), \(self), 在 data source method 中，cell 的 content configuration 應該要是 UIListContentConfiguration，但是中途被改掉了。")
            return
        }
        
        contentConfiguration.secondaryText = String(numberOfDays)
        
        cell.contentConfiguration = contentConfiguration
    }
    
    final func reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode: ResponseDataModel.CurrencyCode) {
        guard editedBaseCurrencyCode != baseCurrencyCode else { return }
        
        editedBaseCurrencyCode = baseCurrencyCode
        
        let baseCurrencyIndexPath = IndexPath(row: Row.baseCurrency.rawValue, section: 0)
        tableView.reloadRows(at: [baseCurrencyIndexPath], with: .automatic)
    }
    
    final func reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>) {
        guard editedCurrencyCodeOfInterest != currencyCodeOfInterest else { return }
        
        editedCurrencyCodeOfInterest = currencyCodeOfInterest
        
        let currencyOfInterestIndexPath = IndexPath(row: Row.currencyOfInterest.rawValue, section: 0)
        tableView.reloadRows(at: [currencyOfInterestIndexPath], with: .automatic)
    }
    
    final func displayStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        Locale.autoupdatingCurrent.localizedString(forCurrencyCode: currencyCode) ??
        AppUtility.supportedSymbols?[currencyCode] ??
        currencyCode
    }
}

// MARK: - Table view data source
extension BaseSettingTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = R.reuseIdentifier.settingCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        var contentConfiguration = cell.defaultContentConfiguration()
        contentConfiguration.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        contentConfiguration.textToSecondaryTextVerticalPadding = 4
        
        // font
        do {
            contentConfiguration.textProperties.font = UIFont.preferredFont(forTextStyle: .body)
            contentConfiguration.textProperties.adjustsFontForContentSizeCategory = true
            
            contentConfiguration.secondaryTextProperties.font = UIFont.preferredFont(forTextStyle: .subheadline)
            contentConfiguration.secondaryTextProperties.color = UIColor.secondaryLabel
            contentConfiguration.secondaryTextProperties.adjustsFontForContentSizeCategory = true
        }
        
        // content
        do {
            let row = Row(rawValue: indexPath.row)
            switch row {
            case .numberOfDay:
                contentConfiguration.text = R.string.settingScene.numberOfConsideredDay()
                contentConfiguration.secondaryText = String(editedNumberOfDays)
                contentConfiguration.image = UIImage(systemName: "calendar")
                stepper.value = Double(editedNumberOfDays)
                cell.accessoryView = stepper
            case .baseCurrency:
                contentConfiguration.text = R.string.share.baseCurrency()
                contentConfiguration.secondaryText = displayStringFor(currencyCode: editedBaseCurrencyCode)
                contentConfiguration.image = UIImage(systemName: "dollarsign.circle")
                cell.accessoryType = .disclosureIndicator
            case .currencyOfInterest:
                contentConfiguration.text = R.string.share.currencyOfInterest()
                
                let editedCurrencyNameOfInterest = editedCurrencyCodeOfInterest
                    .map(self.displayStringFor(currencyCode:))
                    .sorted()
                
                let displayStringForEditedCurrencyNameOfInterest = ListFormatter.localizedString(byJoining: editedCurrencyNameOfInterest)
                
                contentConfiguration.secondaryText = displayStringForEditedCurrencyNameOfInterest
                contentConfiguration.image = UIImage(systemName: "checklist")
                cell.accessoryType = .disclosureIndicator
            case .language:
                contentConfiguration.text = R.string.settingScene.language()
                if let languageCode = Bundle.main.preferredLocalizations.first {
                    contentConfiguration.secondaryText = Locale.autoupdatingCurrent.localizedString(forLanguageCode: languageCode)
                }
                contentConfiguration.image = UIImage(systemName: "character")
                cell.accessoryType = .disclosureIndicator
            case .removeFile:
                contentConfiguration.text = R.string.settingScene.removeFiles()
                contentConfiguration.secondaryText = R.string.settingScene.removeFilesDescription()
                contentConfiguration.image = UIImage(systemName: "folder.badge.minus")
                cell.accessoryType = .none
#if DEBUG
            case .debugInfo:
                contentConfiguration.text = R.string.settingScene.debugInfo()
                contentConfiguration.secondaryText = nil
                contentConfiguration.image = UIImage(systemName: "ladybug")
                cell.accessoryType = .disclosureIndicator
#endif
            case nil:
                assertionFailure("###, \(#function), \(self), SettingTableViewController.Row 新增了 case，未處理新增的 case。")
            }
        }
        
        cell.contentConfiguration = contentConfiguration
        
        return cell
    }
}

// MARK: - Table view delegate
extension BaseSettingTableViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let row = Row(rawValue: indexPath.row)
        switch row {
        case .numberOfDay:
            return nil
        case .baseCurrency, .currencyOfInterest, .language, .removeFile:
            return indexPath
#if DEBUG
        case .debugInfo:
            return indexPath
#endif
        case nil:
            assertionFailure("###, \(#function), \(self), SettingTableViewController.Row 新增了 case，未處理新增的 case。")
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row(rawValue: indexPath.row)
        switch row {
        case .numberOfDay:
            assertionFailure("###, \(#function), \(self), number of day 這個 row 在 tableView(_:willSelectRowAt:) 被設定成不能被點")
            
        case .baseCurrency:
            let identifier = R.segue.settingTableViewController.showBaseCurrencyTableViewController.identifier
            performSegue(withIdentifier: identifier, sender: self)
            
        case .currencyOfInterest:
            let identifier = R.segue.settingTableViewController.showCurrencyOfInterestTableViewController.identifier
            performSegue(withIdentifier: identifier, sender: self)
            
        case .language:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            tableView.deselectRow(at: indexPath, animated: true)
            
        case .removeFile:
            RateController.shared.removeCachedAndStoredData()
            presentAlert(message: R.string.settingScene.dataHaveBeenRemoved())
            tableView.deselectRow(at: indexPath, animated: true)
#if DEBUG
        case .debugInfo:
            let identifier = R.segue.settingTableViewController.showDebugInfo.identifier
            performSegue(withIdentifier: identifier, sender: self)
#endif
            
        case nil:
            assertionFailure("###, \(#function), \(self), SettingTableViewController.Row 新增了 case，未處理新增的 case。")
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        Row(rawValue: indexPath.row) != .numberOfDay
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        section == 0 ? sectionFooterView : nil
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        section == 0 ? UITableView.automaticDimension : 0
    }
}

// MARK: - Adaptive Presentation Controller Delegate
extension BaseSettingTableViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentDismissalConfirmation(withSaveOption: true)
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        print("###, \(self), \(#function), aa,")
    }
}

// MARK: - name space
extension BaseSettingTableViewController {
    /// 表示 table view 的 row
    enum Row: Int, CaseIterable {
        case numberOfDay = 0
        case baseCurrency
        case currencyOfInterest
        case language
        case removeFile
#if DEBUG
        case debugInfo
#endif
    }
}
