import UIKit

class BaseSettingTableViewController: UITableViewController, AlertPresenter {
    // MARK: - initializer
    init?(coder: NSCoder, baseSettingModel: BaseSettingModel) {
        stepper = UIStepper()
        
        self.baseSettingModel = baseSettingModel
        
        super.init(coder: coder)
        
        do /*configure stepper*/ {
            let handler: UIAction = UIAction { [unowned self] _ in stepperValueDidChange() }
            stepper.addAction(handler, for: .primaryActionTriggered)
        }
        
        title = R.string.settingScene.setting()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do /*configure version label*/ {
            versionLabel.font = UIFont.preferredFont(forTextStyle: .callout)
            versionLabel.textColor = UIColor.secondaryLabel
            versionLabel.adjustsFontForContentSizeCategory = true
            let appVersionString: String? = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            versionLabel.text = R.string.settingScene.version(appVersionString ?? "", AppUtility.gitHash)
        }
        
        do /*configure date label*/ {
            dateLabel.font = UIFont.preferredFont(forTextStyle: .callout)
            dateLabel.textColor = UIColor.secondaryLabel
            dateLabel.adjustsFontForContentSizeCategory = true
            let commitDate: Date = Date(timeIntervalSince1970: Double(AppUtility.commitTimestamp))
            let dateString: String = commitDate.formatted(date: .numeric, time: .complete)
            
            dateLabel.text = R.string.settingScene.versionDate(dateString)
        }
    }
    
    // MARK: - instance properties
    private let baseSettingModel: BaseSettingModel
    
    // MARK: - view
    private let stepper: UIStepper
    
    @ViewLoading @IBOutlet private var saveButton: UIBarButtonItem
    
    @ViewLoading @IBOutlet private var sectionFooterView: UIView
    
    @ViewLoading @IBOutlet private var versionLabel: UILabel
    
    @ViewLoading @IBOutlet private var dateLabel: UILabel
    
    // MARK: - kind of abstract method
    // 這樣做的原因是想把兩個 target 共用的 code（設定 `UIAction`）寫在一起。
    // 而內容使用到的 model 的 method 的方式不同，所以無法共用。
    // swiftlint:disable unavailable_function
    func stepperValueDidChange() { fatalError("stepperValueDidChange() has not been implemented") }
    
    // swiftlint:disable:next private_action
    @IBAction func didTapCancelButton(_ sender: UIBarButtonItem) { fatalError("didTapCancelButton(_:) has not been implemented") }
    // swiftlint:enable unavailable_function
}

// MARK: - private methods: Navigation
private extension BaseSettingTableViewController {
    @IBSegueAction final func showBaseCurrencySelectionTableViewController(_ coder: NSCoder) -> CurrencySelectionTableViewController? {
        CurrencySelectionTableViewController(coder: coder,
                                             currencySelectionModel: baseSettingModel.makeBaseCurrencySelectionModel())
    }
    
    @IBSegueAction final func showCurrencyOfInterestSelectionTableViewController(_ coder: NSCoder) -> CurrencySelectionTableViewController? {
        CurrencySelectionTableViewController(coder: coder,
                                             currencySelectionModel: baseSettingModel.makeCurrencyOfInterestSelectionModel())
    }
}

// MARK: - internal method
extension BaseSettingTableViewController {
    /// 向使用者確認是否要取消，尤其是使用者已編輯時，詢問使用者是否要儲存
    final func presentDismissalConfirmation(withSaveOption: Bool) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if withSaveOption {
            let saveAction: UIAlertAction = UIAlertAction(title: R.string.settingScene.cancelAlertSavingTitle(),
                                                          style: .default) { [unowned self] _ in save() }
            alertController.addAction(saveAction)
        }
        
        do /*捨棄變更的 action*/ {
            let discardChangeAction: UIAlertAction = UIAlertAction(title: R.string.settingScene.cancelAlertDiscardTitle(),
                                                                   style: .default) { [unowned self] _ in cancel() }
            
            alertController.addAction(discardChangeAction)
        }
        
        do /*繼續編輯的 action*/ {
            let continueSettingAction: UIAlertAction = UIAlertAction(title: R.string.settingScene.cancelAlertContinueTitle(),
                                                                     style: .cancel)
            
            alertController.addAction(continueSettingAction)
        }
        
        present(alertController, animated: true)
    }
    
    final func updateNumberOfDaysRow() {
        let numberOfDaysRow: IndexPath = IndexPath(row: Row.numberOfDays.rawValue, section: 0)
        
        guard let cell = tableView.cellForRow(at: numberOfDaysRow) else {
            assertionFailure("###, \(#function), \(self), 拿不到設定 number of day 的 cell。")
            return
        }
        
        guard var contentConfiguration = cell.contentConfiguration as? UIListContentConfiguration else {
            assertionFailure("###, \(#function), \(self), 在 data source method 中，cell 的 content configuration 應該要是 UIListContentConfiguration，但是中途被改掉了。")
            return
        }
        
        contentConfiguration.secondaryText = String(baseSettingModel.numberOfDays)
        
        cell.contentConfiguration = contentConfiguration
    }
    
    final func reloadBaseCurrencyRow() {
        let baseCurrencyIndexPath: IndexPath = IndexPath(row: Row.baseCurrency.rawValue, section: 0)
        tableView.reloadRows(at: [baseCurrencyIndexPath], with: .automatic)
    }
    
    final func reloadCurrencyOfInterestRow() {
        let currencyOfInterestIndexPath: IndexPath = IndexPath(row: Row.currencyOfInterest.rawValue, section: 0)
        tableView.reloadRows(at: [currencyOfInterestIndexPath], with: .automatic)
    }
    
    final func displayStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String { // TODO: rename or to remove
        baseSettingModel.displayStringFor(currencyCode: currencyCode)
    }
    
    final func updateFor(hasModificationsToSave: Bool) {
        saveButton.isEnabled = hasModificationsToSave
        isModalInPresentation = hasModificationsToSave
    }
    
    final func cancel() {
        baseSettingModel.cancel()
        dismiss(animated: true)
    }
    
    final func getStepperValue() -> Double { stepper.value }
    
    @IBAction final func save() { // swiftlint:disable:this private_action
        baseSettingModel.save()
        dismiss(animated: true)
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
        
        var contentConfiguration: UIListContentConfiguration = cell.defaultContentConfiguration()
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
            let row: Row? = Row(rawValue: indexPath.row)
            switch row {
                case .numberOfDays:
                    contentConfiguration.text = R.string.settingScene.numberOfConsideredDay()
                    contentConfiguration.secondaryText = String(baseSettingModel.numberOfDays)
                    contentConfiguration.image = UIImage(systemSymbol: .calendar)
                    stepper.value = Double(baseSettingModel.numberOfDays)
                    cell.accessoryView = stepper
                case .baseCurrency:
                    contentConfiguration.text = R.string.share.baseCurrency()
                    contentConfiguration.secondaryText = displayStringFor(currencyCode: baseSettingModel.baseCurrencyCode)
                    contentConfiguration.image = UIImage(systemSymbol: .dollarsignCircle)
                    cell.accessoryType = .disclosureIndicator
                case .currencyOfInterest:
                    contentConfiguration.text = R.string.share.currencyOfInterest()
                    
                    let currencyNameOfInterest: [String] = baseSettingModel.currencyCodeOfInterest
                        .map(self.displayStringFor(currencyCode:))
                        .sorted()
                    
                    let displayStringForCurrencyNameOfInterest: String = ListFormatter.localizedString(byJoining: currencyNameOfInterest)
                    
                    contentConfiguration.secondaryText = displayStringForCurrencyNameOfInterest
                    contentConfiguration.image = UIImage(systemSymbol: .checklistUnchecked)
                    cell.accessoryType = .disclosureIndicator
                case .language:
                    contentConfiguration.text = R.string.settingScene.language()
                    if let languageCode = Bundle.main.preferredLocalizations.first {
                        contentConfiguration.secondaryText = Locale.autoupdatingCurrent.localizedString(forLanguageCode: languageCode)
                    }
                    contentConfiguration.image = UIImage(systemSymbol: .character)
                    cell.accessoryType = .disclosureIndicator
                case .removeFile:
                    contentConfiguration.text = R.string.settingScene.removeFiles()
                    contentConfiguration.secondaryText = R.string.settingScene.removeFilesDescription()
                    contentConfiguration.image = UIImage(systemSymbol: .folderBadgeMinus)
                    cell.accessoryType = .none
#if DEBUG
                case .debugInfo:
                    contentConfiguration.text = R.string.settingScene.debugInfo()
                    contentConfiguration.secondaryText = nil
                    contentConfiguration.image = UIImage(systemSymbol: .ladybug)
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
        let row: Row? = Row(rawValue: indexPath.row)
        switch row {
            case .numberOfDays:
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
        let row: Row? = Row(rawValue: indexPath.row)
        switch row {
            case .numberOfDays:
                assertionFailure("###, \(#function), \(self), number of day 這個 row 在 tableView(_:willSelectRowAt:) 被設定成不能被點")
                
            case .baseCurrency:
                let identifier = R.segue.settingTableViewController.showBaseCurrencySelectionTableViewController.identifier
                performSegue(withIdentifier: identifier, sender: self)
                
            case .currencyOfInterest:
                let identifier = R.segue.settingTableViewController.showCurrencyOfInterestSelectionTableViewController.identifier
                performSegue(withIdentifier: identifier, sender: self)
                
            case .language:
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                tableView.deselectRow(at: indexPath, animated: true)
                
            case .removeFile:
                RateManager.shared.removeCachedAndStoredData()
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
        Row(rawValue: indexPath.row) != .numberOfDays
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
        baseSettingModel.cancel()
    }
}

// MARK: - name space
extension BaseSettingTableViewController {
    /// 表示 table view 的 row
    enum Row: Int, CaseIterable {
        case numberOfDays = 0
        case baseCurrency
        case currencyOfInterest
        case language
        case removeFile
#if DEBUG
        case debugInfo
#endif
    }
}
