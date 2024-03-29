import Foundation

protocol HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           historicalRateResultHandler: @escaping HistoricalRateResultHandler)
}

extension HistoricalRateProviderProtocol {
    typealias HistoricalRateResultHandler = (_ result: Result<ResponseDataModel.HistoricalRate, Error>) -> Void
}
