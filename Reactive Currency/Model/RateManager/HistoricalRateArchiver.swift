import Foundation
import Combine

class HistoricalRateArchiver: BaseHistoricalRateArchiver {}

extension HistoricalRateArchiver: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> {
        if hasFileInDisk(historicalRateDateString: dateString) {
            return Future<ResponseDataModel.HistoricalRate, Error> { [unowned self] promise in
                do {
                    let unarchivedHistoricalRate = try unarchive(historicalRateDateString: dateString)
                    promise(.success(unarchivedHistoricalRate))
                }
                catch {
                    promise(.failure(error))
                }
            }
            .catch { [unowned self] _ in
                nextHistoricalRateProvider
                    .historicalRatePublisherFor(dateString: dateString)
                    .handleEvents(
                        receiveOutput: { [unowned self] historicalRate in try? archive(historicalRate: historicalRate) }
                    )
            }
            .eraseToAnyPublisher()
        }
        else {
            return nextHistoricalRateProvider
                .historicalRatePublisherFor(dateString: dateString)
                .handleEvents(
                    receiveOutput: { [unowned self] historicalRate in try? archive(historicalRate: historicalRate) }
                )
                .eraseToAnyPublisher()
        }
    }
}
