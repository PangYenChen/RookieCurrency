import UIKit

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - initializer
    init?(coder: NSCoder,
          model: SettingModel) {
        self.settingModel = model
        
        super.init(coder: coder, baseSettingModel: model)
        
        self.editedNumberOfDays = model.editedNumberOfDays
        self.editedBaseCurrencyCode = model.editedBaseCurrencyCode
        self.editedCurrencyCodeOfInterest = model.editedCurrencyCodeOfInterest
        
        stepper.value = Double(model.editedNumberOfDays)
        
        isModalInPresentation = model.hasChangeToSave
        hasChangesToSave = model.hasChangeToSave
    }
    
    // MARK: - life cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateForModelHasChangesToSaveIfNeeded(settingModel.hasChangeToSave)
        reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode: settingModel.editedBaseCurrencyCode)
        reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest: settingModel.editedCurrencyCodeOfInterest)
    }
    
    // MARK: - private property
    private let settingModel: SettingModel
    
    // MARK: - hook methods
    override func stepperValueDidChange() {
        updateForModelHasChangesToSaveIfNeeded(settingModel.hasChangeToSave)
        
        updateNumberOfDaysRow(for: settingModel.editedNumberOfDays)
    }
}
