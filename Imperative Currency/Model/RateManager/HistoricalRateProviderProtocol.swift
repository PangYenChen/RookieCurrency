import Foundation

protocol HistoricalRateProviderProtocol: BaseHistoricalRateProviderProtocol {
    func rateFor(dateString: String,
                 resultHandler: @escaping HistoricalRateResultHandler)
}

extension HistoricalRateProviderProtocol {
    typealias HistoricalRateResultHandler = (_ historicalRateResult: Result<ResponseDataModel.HistoricalRate, Error>) -> Void
}
