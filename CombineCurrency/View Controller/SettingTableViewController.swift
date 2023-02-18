//
//  SettingTableViewController.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/2/17.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import UIKit
import Combine

class SettingTableViewController: UITableViewController {
    
    // MARK: - properties
    @IBOutlet private weak var saveButton: UIBarButtonItem!
    
    private let stepper: UIStepper
    
    private let originalNumberOfDay: Int
    
    private let editedNumberOfDay: CurrentValueSubject<Int, Never>
    
    private let originalBaseCurrency: Currency
    
    private let editedBaseCurrency: CurrentValueSubject<Currency, Never>
    
    private let hasChanges: AnyPublisher<Bool, Never>
    
    private let didTapCancelButtonSubject: PassthroughSubject<Void, Never>
    
    private let didTapSaveButtonSubject: PassthroughSubject<Void, Never>
    
    private let updateSetting: PassthroughSubject<(numberOfDay: Int, baseCurrency: Currency), Never>
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: Currency,
                   updateSetting: PassthroughSubject<(numberOfDay: Int, baseCurrency: Currency), Never>) {
        
        do { // number of day
            originalNumberOfDay = numberOfDay
            editedNumberOfDay = CurrentValueSubject(numberOfDay)
        }
        
        do { // stepper
            stepper = UIStepper()
            stepper.value = Double(numberOfDay)
        }
        
        do { // base currency
            originalBaseCurrency = baseCurrency
            editedBaseCurrency = CurrentValueSubject(baseCurrency)
        }
        
        do {
            self.updateSetting = updateSetting
        }
        
        didTapCancelButtonSubject = PassthroughSubject()
        
        didTapSaveButtonSubject = PassthroughSubject()
        
        do {
            let numberOfDayHasChanges = editedNumberOfDay.map { $0 != numberOfDay }
            let baseCurrencyHasChanges = editedBaseCurrency.map { $0 != baseCurrency }
            hasChanges = Publishers.CombineLatest(numberOfDayHasChanges, baseCurrencyHasChanges)
                .map { $0 || $1 }
                .eraseToAnyPublisher()
        }

        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
        
        do { // stepper
            let handler = UIAction { [unowned self] _ in editedNumberOfDay.send(Int(stepper.value)) }
            stepper.addAction(handler, for: .primaryActionTriggered)
        }
        
        do { // other set up
            title = R.string.localizable.setting()
        }
        
        didTapCancelButtonSubject
            .withLatestFrom(hasChanges)
            .sink { [unowned self] _, hasChanges in hasChanges ? presentCancelAlert(showingSave: false) : dismiss(animated: true) }
            .store(in: &anyCancellableSet)
        
        didTapSaveButtonSubject
            .withLatestFrom(editedNumberOfDay)
            .map { $1 }
            .withLatestFrom(editedBaseCurrency)
            .sink { [unowned self] (numberOfDay, baseCurrency) in
                updateSetting.send((numberOfDay, baseCurrency))
                dismiss(animated: true)
            }
            .store(in: &anyCancellableSet)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            editedNumberOfDay
                .sink { [unowned self] editedNumberOfDay in
                    tableView.reloadRows(at: [IndexPath(row: Row.numberOfDay.rawValue, section: 0)], with: .none)
                }
                .store(in: &anyCancellableSet)
            
            editedBaseCurrency
                .sink { [unowned self] editedBaseCurrency in
                    tableView.reloadRows(at: [IndexPath(row: Row.baseCurrency.rawValue, section: 0)], with: .none)
                }
                .store(in: &anyCancellableSet)
            
            hasChanges
                .sink { [unowned self] hasChanges in
                    saveButton.isEnabled = hasChanges
                    isModalInPresentation = hasChanges
                }
                .store(in: &anyCancellableSet)
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBSegueAction private func showCurrencyTable(_ coder: NSCoder) -> CurrencyTableViewController? {
        let editedBaseCurrency = PassthroughSubject<Currency, Never>()
        
        editedBaseCurrency
            .sink { [unowned self] editedBaseCurrency in self.editedBaseCurrency.send(editedBaseCurrency) }
            .store(in: &anyCancellableSet)
        
        return CurrencyTableViewController(coder: coder, editedBaseCurrency: editedBaseCurrency)
    }
    
    @IBAction private func save() {
        didTapSaveButtonSubject.send()
    }
    
    @IBAction private func didTapCancelButton() {
        didTapCancelButtonSubject.send()
    }
    
    private func presentCancelAlert(showingSave: Bool) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if showingSave { // 儲存的 action，只有在下拉的時候加上這個 action。
            let title = R.string.localizable.cancelAlertSavingTitle()
            let saveAction = UIAlertAction(title: title,
                                           style: .default) { [unowned self] _ in save() }
            alertController.addAction(saveAction)
        }
        
        do { // 捨棄變更的 action
            let title = R.string.localizable.cancelAlertDiscardTitle()
            let discardChangeAction = UIAlertAction(title: title,
                                                    style: .default) { [unowned self] _ in dismiss(animated: true) }
            
            alertController.addAction(discardChangeAction)
        }
        
        do { // 繼續編輯的 action
            let title = R.string.localizable.cancelAlertContinueTitle()
            let continueSettingAction = UIAlertAction(title: title, style: .cancel)
            
            alertController.addAction(continueSettingAction)
        }
        
        present(alertController, animated: true)
    }
    
}

// MARK: - Table view data source
extension SettingTableViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        Row.allCases.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = R.reuseIdentifier.settingCell.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        do { // font
            cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
            cell.textLabel?.adjustsFontForContentSizeCategory = true
            
            cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
            cell.detailTextLabel?.adjustsFontForContentSizeCategory = true
        }
        
        do { // content
            let row = Row(rawValue: indexPath.row)
            switch row {
            case .numberOfDay:
                cell.textLabel?.text = R.string.localizable.numberOfConsideredDay()
                cell.detailTextLabel?.text = String(editedNumberOfDay.value)
                cell.accessoryView = stepper
                cell.imageView?.image = UIImage(systemName: "calendar")
            case .baseCurrency:
                cell.textLabel?.text = R.string.localizable.baseCurrency()
                cell.detailTextLabel?.text = editedBaseCurrency.value.localizedString
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "dollarsign.circle")
            case .language:
                cell.textLabel?.text = R.string.localizable.language()
                if let languageCode = Bundle.main.preferredLocalizations.first {
                    cell.detailTextLabel?.text = Locale.current.localizedString(forLanguageCode: languageCode)
                }
                cell.accessoryType = .disclosureIndicator
                cell.imageView?.image = UIImage(systemName: "character")
            default:
                assertionFailure("###, \(#function), \(self), SettingTableViewController.Row 新增了 case，未處理新增的 case。")
            }
        }
        
        return cell
    }
}

// MARK: - Table view delegate
extension SettingTableViewController {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let row = Row(rawValue: indexPath.row)
        switch row {
        case .baseCurrency, .language:
            return indexPath
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = Row(rawValue: indexPath.row)
        switch row {
        case .baseCurrency:
            performSegue(withIdentifier: R.segue.settingTableViewController.showCurrencyTable, sender: self)
        case .language:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        Row(rawValue: indexPath.row) != .numberOfDay
    }
}

// MARK: - Adaptive Presentation Controller Delegate
extension SettingTableViewController: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        presentCancelAlert(showingSave: true)
    }
}

// MARK: - name space
private extension SettingTableViewController {
    /// 表示 table view 的 row
    enum Row: Int, CaseIterable {
        case numberOfDay = 0
        case baseCurrency
        case language
    }
}
