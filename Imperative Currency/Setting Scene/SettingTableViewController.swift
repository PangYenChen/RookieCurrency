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
        
        isModalInPresentation = model.hasChange
        hasChangesToSave = model.hasChange
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateForModelHasChangesToSaveIfNeeded(model.hasChange)
        reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode: model.editedBaseCurrencyCode)
        reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest: model.editedCurrencyCodeOfInterest)
    }
    
    // MARK: - hook methods
    override func stepperValueDidChange() {
        updateForModelHasChangesToSaveIfNeeded(model.hasChange)
        
        updateNumberOfDaysRow(for: model.editedNumberOfDays)
    }
    
    // MARK: - Navigation
    override func showBaseCurrencySelectionTableViewController(_ coder: NSCoder) -> CurrencySelectionTableViewController? {
        CurrencySelectionTableViewController(coder: coder,
                                             currencySelectionModel: model.makeBaseCurrencySelectionModel())
    }
    
    override func showCurrencyOfInterestSelectionTableViewController(_ coder: NSCoder) -> CurrencySelectionTableViewController? {
        CurrencySelectionTableViewController(coder: coder,
                                             currencySelectionModel: model.makeCurrencyOfInterestSelectionModel())
    }
}
