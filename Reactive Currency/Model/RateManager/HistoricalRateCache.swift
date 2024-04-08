import Foundation
import Combine

class HistoricalRateCache: BaseHistoricalRateCache {}

extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func publisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        if let cachedRate = concurrentDispatchQueue.sync(execute: { dateStringAndRateDirectory[dateString] }) {
            return Just(cachedRate)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            return nextHistoricalRateProvider.publisherFor(dateString: dateString)
                .handleEvents(receiveOutput: { [unowned self] rate in
                    concurrentDispatchQueue.async(flags: .barrier) {
                        dateStringAndRateDirectory[rate.dateString] = rate
                    }
                })
                .eraseToAnyPublisher()
        }
    }
}
