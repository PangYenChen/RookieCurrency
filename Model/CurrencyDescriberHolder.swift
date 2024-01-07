import Foundation

protocol CurrencyDescriberHolder: CurrencyDescriberProtocol {
    var currencyDescriber: CurrencyDescriberProtocol { get }
}

extension CurrencyDescriberHolder {
    func displayStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        currencyDescriber.displayStringFor(currencyCode: currencyCode)
    }
}
