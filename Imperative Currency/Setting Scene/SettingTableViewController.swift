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
        
        settingModel.editedBaseCurrencyCodeDidChangeHandler = reloadBaseCurrencyRow
        settingModel.editedCurrencyCodeOfInterestDidChangeHandler = reloadCurrencyOfInterestRow
        settingModel.hasModificationsToSaveHandler = updateFor(hasModificationsToSave:)
        
        updateFor(hasModificationsToSave: settingModel.hasModificationsToSave)
    }
    
    // MARK: - private property
    private let settingModel: SettingModel
    
    // MARK: - override abstract method
    override func stepperValueDidChange() {
        settingModel.numberOfDays = Int(getStepperValue())
        updateNumberOfDaysRow()
    }
    
    override func didTapCancelButton(_ sender: UIBarButtonItem) {
        settingModel.hasModificationsToSave ? presentDismissalConfirmation(withSaveOption: false) : cancel()
    }
}
