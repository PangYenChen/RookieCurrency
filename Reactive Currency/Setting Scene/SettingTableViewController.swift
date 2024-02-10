import UIKit
import Combine

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - private properties
    private let settingModel: SettingModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - methods
    init?(coder: NSCoder,
          model: SettingModel) {
        self.settingModel = model
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, baseSettingModel: model)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingModel.editedNumberOfDays
            .dropFirst()
            .sink { [unowned self] numberOfDays in
                self.updateNumberOfDaysRow(for: numberOfDays)
                self.editedNumberOfDays = numberOfDays
            }
            .store(in: &anyCancellableSet)
        
        settingModel.editedNumberOfDays
            .first()
            .sink { [unowned self] numberOfDays in
                self.editedNumberOfDays = numberOfDays
                // table view 在 viewIsAppearing 跟 viewDidAppear 之間才會第一次 call data source method
                // 所以這時候無法透過 table view 的 cellForRow(at:) 拿到 cell
                // 只能讓 table view 自己處理
            }
            .store(in: &anyCancellableSet)
        
        settingModel.editedBaseCurrencyCode
            .sink(receiveValue: self.reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode:))
            .store(in: &anyCancellableSet)
        
        settingModel.editedCurrencyCodeOfInterest
            .sink(receiveValue: self.reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest:))
            .store(in: &anyCancellableSet)
        
        settingModel.hasChangesToSave
            .sink(receiveValue: self.updateForModelHasChangesToSaveIfNeeded(_:))
            .store(in: &anyCancellableSet)
    }
    
    override func stepperValueDidChange() {
        settingModel.editedNumberOfDays.send(Int(stepper.value))
    }
}
