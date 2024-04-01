import Foundation
import Combine

class HistoricalRateProvider: BaseHistoricalRateProvider {}

extension HistoricalRateProvider: HistoricalRateProviderProtocol {
    func publisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        historicalRateCache.publisherFor(dateString: dateString)
    }
}
