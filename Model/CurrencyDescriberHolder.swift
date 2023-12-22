import Foundation

protocol CurrencyDescriberHolder: CurrencyDescriber {
    var currencyDescriber: CurrencyDescriber { get }
}

extension CurrencyDescriberHolder {
    func displayStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        currencyDescriber.displayStringFor(currencyCode: currencyCode)
    }
}
