import Foundation
import Combine

class HistoricalRateProvider: BaseHistoricalRateProvider {}

extension HistoricalRateProvider: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        historicalRateCache.historicalRatePublisherFor(dateString: dateString)
    }
}
