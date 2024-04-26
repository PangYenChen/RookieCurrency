import Foundation

extension ResponseDataModel {
    struct SupportedSymbols: Decodable {
        let symbols: [ResponseDataModel.CurrencyCode: String]
    }
}
