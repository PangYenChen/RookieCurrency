import Foundation
import Combine

class HistoricalRateProviderChain: BaseHistoricalRateProviderChain {}

extension HistoricalRateProviderChain: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        nextHistoricalRateProvider.historicalRatePublisherFor(dateString: dateString)
    }
}
