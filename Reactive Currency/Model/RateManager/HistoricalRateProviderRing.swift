import Combine

class HistoricalRateProviderRing: BaseHistoricalRateProviderRing {}

extension HistoricalRateProviderRing: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        if let storedRate = storage.readFor(dateString: dateString) {
            return Just(storedRate)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            return nextProvider.historicalRatePublisherFor(dateString: dateString)
                .handleEvents(receiveOutput: { [unowned self] rate in storage.store(rate) })
                .eraseToAnyPublisher()
        }
    }
}
