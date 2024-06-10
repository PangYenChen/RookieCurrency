import Foundation

protocol HistoricalRateProviderProtocol: BaseHistoricalRateProviderProtocol {
    func historicalRateFor(dateString: String,
                           id: String,
                           resultHandler: @escaping HistoricalRateResultHandler)
}

extension HistoricalRateProviderProtocol {
    typealias HistoricalRateResultHandler = (_ rateResult: Result<ResponseDataModel.HistoricalRate, Error>) -> Void
}
