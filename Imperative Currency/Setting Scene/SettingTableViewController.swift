import UIKit

class SettingTableViewController: BaseSettingTableViewController {
    
    // MARK: - properties
    private let model: SettingModel
    
    // MARK: - methods
    required init?(coder: NSCoder,
                   numberOfDay: Int,
                   baseCurrency: ResponseDataModel.CurrencyCode,
                   currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
                   saveCompletionHandler: @escaping (Int, ResponseDataModel.CurrencyCode, Set<ResponseDataModel.CurrencyCode>) -> Void,
                   cancelCompletionHandler: @escaping () -> Void) {
        
        model = SettingModel(numberOfDays: numberOfDay,
                             baseCurrency: baseCurrency,
                             currencyOfInterest: currencyOfInterest,
                             saveCompletionHandler: saveCompletionHandler,
                             cancelCompletionHandler: cancelCompletionHandler)
        
        super.init(coder: coder)
        
        self.editedNumberOfDays = numberOfDay
        self.editedBaseCurrencyCode = baseCurrency
        self.editedCurrencyCodeOfInterest = currencyOfInterest
        
        stepper.value = Double(numberOfDay)

        isModalInPresentation = model.hasChange
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func stepperValueDidChange() {
        model.editedNumberOfDay = Int(stepper.value)

        saveButton.isEnabled = model.hasChange
        isModalInPresentation = model.hasChange
        
        updateNumberOfDaysRow(for: model.editedNumberOfDay)
    }
    
    @IBAction override func save() {
        model.saveCompletionHandler(model.editedNumberOfDay,
                                    model.editedBaseCurrency,
                                    model.editedCurrencyOfInterest)
        super.save()
    }
    
    override func cancel() {
        model.cancelCompletionHandler()
        super.cancel()
    }
    
    @IBAction private func didTapCancelButton() {
        model.hasChange ? presentDismissalConfirmation(withSaveOption: false) : cancel()
    }
    
    // MARK: - Navigation
    override func showBaseCurrencyTableViewController(_ coder: NSCoder) -> CurrencyTableViewController? {
        
        let baseCurrencySelectionStrategy = CurrencyTableViewController
            .BaseCurrencySelectionStrategy(baseCurrencyCode: model.editedBaseCurrency) { [unowned self] selectedBaseCurrency in
                model.editedBaseCurrency = selectedBaseCurrency
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
