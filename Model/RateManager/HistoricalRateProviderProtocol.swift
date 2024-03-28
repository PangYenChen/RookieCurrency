import Foundation

protocol HistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           historicalRateHandler: @escaping HistoricalRateHandler)
}

extension HistoricalRateProviderProtocol {
    typealias HistoricalRateHandler = (_ result: Result<ResponseDataModel.HistoricalRate, Error>) -> Void
}
