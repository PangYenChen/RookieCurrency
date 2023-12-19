import UIKit

class SettingTableViewController: BaseSettingTableViewController {
    // MARK: - private property
    private let model: SettingModel
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   model: SettingModel) {
        
        self.model = model
        
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
        
        updateForModelHasChangesToSaveIfNeeded(model.hasChangeToSave)
        reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode: model.editedBaseCurrencyCode)
        reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest: model.editedCurrencyCodeOfInterest)
    }
    
    // MARK: - hook methods
    override func stepperValueDidChange() {
        updateForModelHasChangesToSaveIfNeeded(model.hasChangeToSave)
        
        updateNumberOfDaysRow(for: model.editedNumberOfDays)
    }
}
