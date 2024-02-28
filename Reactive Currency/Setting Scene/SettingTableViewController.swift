import UIKit
import Combine

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - initializer
    init?(coder: NSCoder,
          model: SettingModel) {
        self.settingModel = model
        
        anyCancellableSet = Set<AnyCancellable>()
        
        super.init(coder: coder, baseSettingModel: model)
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: 這些東西在第一次進來畫面，table veiw本身會 load 一次，這裡會不會多load一次？
        settingModel.editedNumberOfDaysPublisher
            .dropFirst()
            .sink { [unowned self] numberOfDays in updateNumberOfDaysRow(for: numberOfDays) }
            .store(in: &anyCancellableSet)
        
        settingModel.editedBaseCurrencyCodePublisher
            .sink(receiveValue: self.reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode:))
            .store(in: &anyCancellableSet)
        
        settingModel.editedCurrencyCodeOfInterest
            .sink(receiveValue: self.reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest:))
            .store(in: &anyCancellableSet)
        
        settingModel.hasChangesToSave
            .sink(receiveValue: self.updateForModelHasChangesToSaveIfNeeded(_:))
            .store(in: &anyCancellableSet)
    }
    
    // MARK: - private properties
    private let settingModel: SettingModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - kind of abstract method
    override func stepperValueDidChange() {
        settingModel.set(editedNumberOfDays: Int(stepper.value))
    }
}
