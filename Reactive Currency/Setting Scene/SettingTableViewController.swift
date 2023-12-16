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
        
        super.init(coder: coder, baseSettingModel: model)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        
        model.editedBaseCurrencyCode
            .sink(receiveValue: self.reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode:))
            .store(in: &anyCancellableSet)
        
        model.editedCurrencyCodeOfInterest
            .sink(receiveValue: self.reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest:))
            .store(in: &anyCancellableSet)
        
        model.hasChangesToSave
            .sink { [unowned self] hasChangesToSave in
                self.hasChangesToSave = hasChangesToSave
                saveButton.isEnabled = hasChangesToSave
                isModalInPresentation = hasChangesToSave
            }
            .store(in: &anyCancellableSet)
    }
    
    override func stepperValueDidChange() {
        model.editedNumberOfDays.send(Int(stepper.value))
    }
    
    // MARK: - Navigation
    override func showBaseCurrencySelectionTableViewController(_ coder: NSCoder) -> CurrencySelectionTableViewController? {
        let baseCurrencySelectionModel = BaseCurrencySelectionModel(baseCurrencyCode: model.editedBaseCurrencyCode.value,
                                           selectedBaseCurrencyCode: AnySubscriber(model.editedBaseCurrencyCode))
        
        return CurrencySelectionTableViewController(coder: coder, currencySelectionModel: baseCurrencySelectionModel)
    }
    
    override func showCurrencyOfInterestSelectionTableViewController(_ coder: NSCoder) -> CurrencySelectionTableViewController? {
        let currencyOfInterestSelectionModel = CurrencyOfInterestSelectionModel(currencyCodeOfInterest: model.editedCurrencyCodeOfInterest.value,
                                                 selectedCurrencyCodeOfInterest: AnySubscriber(model.editedCurrencyCodeOfInterest))
        
        return CurrencySelectionTableViewController(coder: coder, currencySelectionModel: currencyOfInterestSelectionModel)
    }
}
