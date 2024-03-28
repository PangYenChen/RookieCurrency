import Foundation

protocol HistoricalRateProvider {
    func historicalRateFor(dateString: String, completionHandler: @escaping (Result<ResponseDataModel.HistoricalRate, Error>) ->  Void)
}
