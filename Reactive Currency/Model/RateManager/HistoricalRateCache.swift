import Foundation
import Combine

class HistoricalRateCache: BaseHistoricalRateCache {}

extension HistoricalRateCache: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        let cachedRate: ResponseDataModel.HistoricalRate? = dateStringAndRateDirectoryWrapper
            .readSynchronously { dateStringAndRateDirectory in dateStringAndRateDirectory[dateString] }
        
        if let cachedRate {
            return Just(cachedRate)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            return nextHistoricalRateProvider.historicalRatePublisherFor(dateString: dateString)
                .handleEvents(receiveOutput: { [unowned self] rate in
                    dateStringAndRateDirectoryWrapper.writeAsynchronously { dateStringAndRateDirectory in
                        var dateStringAndRateDirectory: [String: ResponseDataModel.HistoricalRate] = dateStringAndRateDirectory
                        dateStringAndRateDirectory[rate.dateString] = rate
                        
                        return dateStringAndRateDirectory
                    }
                })
                .eraseToAnyPublisher()
        }
    }
}
