import Foundation
import Combine

class HistoricalRateArchiver: BaseHistoricalRateArchiver {}

extension HistoricalRateArchiver: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> {
        if hasFileInDiskWith(dateString: dateString) {
            return Future<ResponseDataModel.HistoricalRate, Error> { [unowned self] promise in
                do {
                    let unarchivedRate: ResponseDataModel.HistoricalRate = try unarchiveRateWith(dateString: dateString)
                    promise(.success(unarchivedRate))
                }
                catch {
                    promise(.failure(error))
                }
            }
            .catch { [unowned self] _ in
                nextHistoricalRateProvider
                    .historicalRatePublisherFor(dateString: dateString)
                    .handleEvents(receiveOutput: { [unowned self] rate in try? archive(rate) })
            }
            .eraseToAnyPublisher()
        }
        else {
            return nextHistoricalRateProvider
                .historicalRatePublisherFor(dateString: dateString)
                .handleEvents(receiveOutput: { [unowned self] rate in try? archive(rate) })
                .eraseToAnyPublisher()
        }
    }
}
