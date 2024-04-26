import Foundation

protocol CurrencyDescriberProxy: CurrencyDescriberProtocol {
    var currencyDescriber: CurrencyDescriberProtocol { get }
}

extension CurrencyDescriberProxy {
    func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        currencyDescriber.localizedStringFor(currencyCode: currencyCode)
    }
}
