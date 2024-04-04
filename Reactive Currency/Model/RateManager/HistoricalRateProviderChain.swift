import Foundation
import Combine

class HistoricalRateProviderChain: BaseHistoricalRateProviderChain {}

extension HistoricalRateProviderChain: HistoricalRateProviderProtocol {
    func publisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        nextHistoricalRateProvider.publisherFor(dateString: dateString)
    }
}
