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
        
        settingModel.numberOfDaysDidChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: updateNumberOfDaysRow)
            .store(in: &anyCancellableSet)
        
        settingModel.baseCurrencyCodeDidChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadBaseCurrencyRow)
            .store(in: &anyCancellableSet)
        
        settingModel.currencyCodeOfInterestDidChange
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: reloadCurrencyOfInterestRow)
            .store(in: &anyCancellableSet)
        
        settingModel.hasModificationsToSave
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: self.updateFor(hasModificationsToSave:))
            .store(in: &anyCancellableSet)
        
        settingModel.cancellationConfirmation
            .receive(on: DispatchQueue.main)
            .sink { [unowned self] in presentDismissalConfirmation(withSaveOption: false) }
            .store(in: &anyCancellableSet)
    }
    
    // MARK: - private properties
    private let settingModel: SettingModel
    
    private var anyCancellableSet: Set<AnyCancellable>
    
    // MARK: - override abstract method
    override func stepperValueDidChange() {
        settingModel.set(numberOfDays: Int(getStepperValue()))
    }
    
    override func didTapCancelButton(_ sender: UIBarButtonItem) {
        settingModel.attemptToCancel()
    }
}
