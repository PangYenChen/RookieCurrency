import Foundation

protocol CurrencySelectionModelProtocol: BaseCurrencySelectionModelProtocol {
    var currencySelectionStrategy: CurrencySelectionStrategy { get }
    var supportedCurrencyManager: SupportedCurrencyManager { get }
}

extension CurrencySelectionModelProtocol {
    var title: String { currencySelectionStrategy.title }
    
    var allowsMultipleSelection: Bool { currencySelectionStrategy.allowsMultipleSelection }
    
    func select(currencyCode selectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencySelectionStrategy.select(currencyCode: selectedCurrencyCode)
    }
    
    func deselect(currencyCode deselectedCurrencyCode: ResponseDataModel.CurrencyCode) {
        currencySelectionStrategy.deselect(currencyCode: deselectedCurrencyCode)
    }
    
    func isCurrencyCodeSelected(_ currencyCode: ResponseDataModel.CurrencyCode) -> Bool {
        currencySelectionStrategy.isCurrencyCodeSelected(currencyCode)
    }
}

extension CurrencySelectionModelProtocol {
    var currencyDescriber: CurrencyDescriber { supportedCurrencyManager }
}
