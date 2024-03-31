import Foundation
import Combine

class HistoricalRateArchiver: BaseHistoricalRateArchiver {}

extension HistoricalRateArchiver: HistoricalRateProviderProtocol {
    func publisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> {
        if hasFileInDiskWith(dateString: dateString) {
            return Future<ResponseDataModel.HistoricalRate, Error> { [unowned self] promise in
                do {
                    let unarchivedHistoricalRate = try unarchiveRateWith(dateString: dateString)
                    promise(.success(unarchivedHistoricalRate))
                }
                catch {
                    promise(.failure(error))
                }
            }
            .catch { [unowned self] _ in
                nextHistoricalRateProvider
                    .publisherFor(dateString: dateString)
                    .handleEvents(
                        receiveOutput: { [unowned self] historicalRate in try? archive(historicalRate) }
                    )
            }
            .eraseToAnyPublisher()
        }
        else {
            return nextHistoricalRateProvider
                .publisherFor(dateString: dateString)
                .handleEvents(
                    receiveOutput: { [unowned self] historicalRate in try? archive(historicalRate) }
                )
                .eraseToAnyPublisher()
        }
    }
}
