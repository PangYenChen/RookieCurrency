import Foundation

protocol CurrencyDescriberProxy: CurrencyDescriberProtocol {
    var currencyDescriber: CurrencyDescriberProtocol { get }
}

extension CurrencyDescriberProxy {
    func displayStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        currencyDescriber.displayStringFor(currencyCode: currencyCode)
    }
}
