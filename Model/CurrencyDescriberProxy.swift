import Foundation

// TODO: 看能不能拿掉
protocol CurrencyDescriberProxy: CurrencyDescriberProtocol {
    var currencyDescriber: CurrencyDescriberProtocol { get }
}

extension CurrencyDescriberProxy {
    func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        currencyDescriber.localizedStringFor(currencyCode: currencyCode)
    }
}
