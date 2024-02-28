import UIKit

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - initializer
    init?(coder: NSCoder,
          model: SettingModel) {
        self.settingModel = model
        
        super.init(coder: coder, baseSettingModel: model)
        
        isModalInPresentation = model.hasChangeToSave
        hasChangesToSave = model.hasChangeToSave
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingModel.editedBaseCurrencyCodeHandler = reloadBaseCurrencyRowFor(baseCurrencyCode:)
        settingModel.editedCurrencyCodeOfInterestHandler = reloadCurrencyOfInterestRowFor(currencyCodeOfInterest:)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateForModelHasChangesToSaveIfNeeded(settingModel.hasChangeToSave)
    }
    
    // MARK: - private property
    private let settingModel: SettingModel
    
    // MARK: - hook methods
    override func stepperValueDidChange() {
        // TODO: 這裡有 bug，漏通知 model
        updateForModelHasChangesToSaveIfNeeded(settingModel.hasChangeToSave)
        
        updateNumberOfDaysRow(for: settingModel.editedNumberOfDays)
    }
}
