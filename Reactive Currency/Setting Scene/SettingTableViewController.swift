import UIKit
import Combine

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - private properties
    private let model: SettingModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   model: SettingModel) {
        self.model = model
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.didTapCancelButtonSubject
            .withLatestFrom(model.hasChanges)
            .sink { [unowned self] _, hasChanges in hasChanges ? presentCancelAlert(showingSave: false) : cancel() }
            .store(in: &anyCancellableSet)
        
        model.editedNumberOfDays
            .dropFirst()
            .sink { [unowned self] numberOfDays in
                self.updateNumberOfDaysRow(for: numberOfDays)
                self.editedNumberOfDays = numberOfDays
            }
            .store(in: &anyCancellableSet)
        
        model.editedNumberOfDays
            .first()
            .sink { [unowned self] numberOfDays in
                self.editedNumberOfDays = numberOfDays
                // table view 在 viewIsAppearing 跟 viewDidAppear 之間才會第一次 call data source method
                // 所以這時候無法透過 table view 的 cellForRow(at:) 拿到 cell
                // 只能讓 table view 自己處理
            }
            .store(in: &anyCancellableSet)
        
        model.editedBaseCurrency
            .sink { [unowned self] editedBaseCurrencyCode in
                self.editedBaseCurrencyCode = editedBaseCurrencyCode
                let baseCurrencyIndexPath = IndexPath(row: Row.baseCurrency.rawValue, section: 0)
                self.tableView.reloadRows(at: [baseCurrencyIndexPath], with: .automatic)
            }
            .store(in: &anyCancellableSet)
        
        model.editedCurrencyOfInterest
            .sink { editedCurrencyCodeOfInterest in
                self.editedCurrencyCodeOfInterest = editedCurrencyCodeOfInterest
                let baseCurrencyIndexPath = IndexPath(row: Row.currencyOfInterest.rawValue, section: 0)
                self.tableView.reloadRows(at: [baseCurrencyIndexPath], with: .automatic)
            }
            .store(in: &anyCancellableSet)
        
        model.hasChanges
            .sink { [unowned self] hasChanges in
                saveButton.isEnabled = hasChanges
                isModalInPresentation = hasChanges
            }
            .store(in: &anyCancellableSet)
    }
    
    override func stepperValueDidChange() {
        model.editedNumberOfDays.send(Int(stepper.value))
    }
    
    override func cancel() {
        super.cancel()
        model.cancelSubject.send()
    }
    
    @IBAction override func save() {
        model.didTapSaveButtonSubject.send()
        super.save()
    }
    
    @IBAction private func didTapCancelButton() {
        model.didTapCancelButtonSubject.send()
    }
    
    // MARK: - Navigation
    override func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        let strategy = CurrencyTableViewController
            .BaseCurrencySelectionStrategy(baseCurrencyCode: model.editedBaseCurrency.value,
                                           selectedBaseCurrencyCode: AnySubscriber(model.editedBaseCurrency))
        
        return CurrencyTableViewController(coder: coder, strategy: strategy)
    }
    
    override func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        let strategy = CurrencyTableViewController
            .CurrencyOfInterestSelectionStrategy(currencyOfInterest: model.editedCurrencyOfInterest.value,
                                                 selectedCurrencyOfInterest: AnySubscriber(model.editedCurrencyOfInterest))
        
        return CurrencyTableViewController(coder: coder, strategy: strategy)
    }
}
