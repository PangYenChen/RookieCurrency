import Foundation

protocol SupportedCurrencyManagerHolder {
    var supportedCurrencyManager: SupportedCurrencyManager { get }
}

extension SupportedCurrencyManagerHolder {
    func displayStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        supportedCurrencyManager.displayStringFor(currencyCode: currencyCode)
    }
}
