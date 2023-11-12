import UIKit
import Combine

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - properties
    private let model: SettingModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   userSetting: BaseResultModel.UserSetting,
                   settingSubscriber: AnySubscriber<(numberOfDay: Int,
                                                     baseCurrency: ResponseDataModel.CurrencyCode,
                                                     currencyOfInterest: Set<ResponseDataModel.CurrencyCode>), Never>,
                   cancelSubscriber: AnySubscriber<Void, Never>) {
        // TODO: 要由 init 這個 class 的 client 傳入 model
        model = SettingModel(userSetting: userSetting,
                             settingSubscriber: settingSubscriber,
                             cancelSubscriber: cancelSubscriber)
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, model: model)
        
        stepper.value = Double(userSetting.numberOfDay)
        
        model.didTapCancelButtonSubject
            .withLatestFrom(model.hasChanges)
            .sink { [unowned self] _, hasChanges in hasChanges ? presentCancelAlert(showingSave: false) : cancel() }
            .store(in: &anyCancellableSet)
        
        model.didTapSaveButtonSubject
            .withLatestFrom(model.editedNumberOfDays)
            .map { $1 }
            .withLatestFrom(model.editedBaseCurrency)
            .withLatestFrom(model.editedCurrencyOfInterest)
            .map { (numberOfDay: $0.0, baseCurrency: $0.1, currencyOfInterest: $1) }
            .subscribe(settingSubscriber)
        
        model.cancelSubject
            .subscribe(cancelSubscriber)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init?(coder: NSCoder, model: BaseSettingModel) {
        fatalError("init(coder:model:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        model.editedNumberOfDays
            .dropFirst()
            .sink { [unowned self] _ in
                
                let numberOfDayRow = IndexPath(row: Row.numberOfDay.rawValue, section: 0)
                
                guard let cell = tableView.cellForRow(at: numberOfDayRow) else {
                    assertionFailure("###, \(#function), \(self), 拿不到設定 number of day 的 cell。")
                    return
                }
                
                guard var contentConfiguration = cell.contentConfiguration as? UIListContentConfiguration else {
                    assertionFailure("###, \(#function), \(self), 在 data source method 中，cell 的 content configuration 應該要是 UIListContentConfiguration，但是中途被改掉了。")
                    return
                }
                
                contentConfiguration.secondaryText = model.editedNumberOfDaysString
                
                cell.contentConfiguration = contentConfiguration
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
