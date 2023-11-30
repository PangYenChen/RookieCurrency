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
        self.editedCurrencyCodeOfInterest = model.editedCurrencyOfInterest
        
        stepper.value = Double(model.editedNumberOfDays)
        
        isModalInPresentation = model.hasChange
        hasChangesToSave = model.hasChange
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        hasChangesToSave = model.hasChange
        
        reloadBaseCurrencyRowIfNeededFor(baseCurrencyCode: model.editedBaseCurrencyCode)
        reloadCurrencyOfInterestRowIfNeededFor(currencyCodeOfInterest: model.editedCurrencyOfInterest)
    }
    
    // MARK: - hook methods
    override func stepperValueDidChange() {
        model.editedNumberOfDays = Int(stepper.value)
        
        hasChangesToSave = model.hasChange
        saveButton.isEnabled = model.hasChange
        isModalInPresentation = model.hasChange
        
        updateNumberOfDaysRow(for: model.editedNumberOfDays)
    }
    
    // MARK: - Navigation
    override func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        let baseCurrencySelectionStrategy = CurrencyTableViewController
            .BaseCurrencySelectionStrategy(baseCurrencyCode: model.editedBaseCurrencyCode) { [unowned self] selectedBaseCurrencyCode in
                model.editedBaseCurrencyCode = selectedBaseCurrencyCode
                saveButton.isEnabled = model.hasChange
                isModalInPresentation = model.hasChange
            }
        
        return CurrencyTableViewController(coder: coder, strategy: baseCurrencySelectionStrategy)
    }
    
    override func showCurrencyOfInterestTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        let currencyOfInterestSelectionStrategy = CurrencyTableViewController
            .CurrencyOfInterestSelectionStrategy(currencyOfInterest: model.editedCurrencyOfInterest) { [unowned self] selectedCurrencyOfInterest in
                model.editedCurrencyOfInterest = selectedCurrencyOfInterest
                saveButton.isEnabled = model.hasChange
                isModalInPresentation = model.hasChange
            }

        return CurrencyTableViewController(coder: coder, strategy: currencyOfInterestSelectionStrategy)
    }
}
