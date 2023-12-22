import UIKit

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - private property
    private let settingModel: SettingModel
    
    // MARK: - methods
    required init?(coder: NSCoder,
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
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateForModelHasChangesToSaveIfNeeded(settingModel.hasChangeToSave)
        reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode: settingModel.editedBaseCurrencyCode)
        reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest: settingModel.editedCurrencyCodeOfInterest)
    }
    
    // MARK: - hook methods
    override func stepperValueDidChange() {
        updateForModelHasChangesToSaveIfNeeded(settingModel.hasChangeToSave)
        
        updateNumberOfDaysRow(for: settingModel.editedNumberOfDays)
    }
}
