import UIKit

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - initializer
    init?(coder: NSCoder,
          model: SettingModel) {
        self.settingModel = model
        
        super.init(coder: coder, baseSettingModel: model)
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingModel.editedBaseCurrencyCodeHandler = reloadBaseCurrencyRowFor(baseCurrencyCode:)
        settingModel.editedCurrencyCodeOfInterestHandler = reloadCurrencyOfInterestRowFor(currencyCodeOfInterest:)
        settingModel.hasChangesToSaveHandler = updateFor(hasChangesToSave:)
        
        updateFor(hasChangesToSave: settingModel.hasChangesToSave)
    }
    
    // MARK: - private property
    private let settingModel: SettingModel
    
    // MARK: - override abstract method
    override func stepperValueDidChange() {
        settingModel.editedNumberOfDays = Int(getStepperValue())
        updateNumberOfDaysRow(for: settingModel.editedNumberOfDays)
    }
    
    override func didTapCancelButton(_ sender: UIBarButtonItem) {
        settingModel.hasChangesToSave ? presentDismissalConfirmation(withSaveOption: false) : cancel()
    }
}
