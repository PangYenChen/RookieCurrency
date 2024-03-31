import Foundation
import Combine

class HistoricalRateCache: BaseHistoricalRateCache {}

extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        if let cachedHistoricalRate = concurrentQueue.sync(execute: { historicalRateDirectory[dateString] }) {
            return Just(cachedHistoricalRate)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            return nextHistoricalRateProvider.historicalRatePublisherFor(dateString: dateString)
                .handleEvents(receiveOutput: { [unowned self] historicalRate in
                    concurrentQueue.async(flags: .barrier) {
                        historicalRateDirectory[historicalRate.dateString] = historicalRate
                    }
                })
                .eraseToAnyPublisher()
        }
    }
}
