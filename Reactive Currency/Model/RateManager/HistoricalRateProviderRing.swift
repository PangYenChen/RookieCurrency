import Combine

class HistoricalRateProviderRing: BaseHistoricalRateProviderRing {}

extension HistoricalRateProviderRing: HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String, traceIdentifier: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, any Error> {
        if let storedRate = storage.readFor(dateString: dateString) {
            logger.debug("trace identifier: \(traceIdentifier), read: \(dateString) from storage: \(String(describing: self.storage))")
            
            return Just(storedRate)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            logger.debug("trace identifier: \(traceIdentifier), starting requesting: \(dateString) from next provider")
            
            return nextProvider.historicalRatePublisherFor(dateString: dateString, traceIdentifier: traceIdentifier)
                .handleEvents(
                    receiveOutput: { [weak self] rate in
                        self?.storage.store(rate)
                        self?.logger.debug("trace identifier: \(traceIdentifier), receive historical rate for date: \(dateString)")
                    },
                    receiveCompletion: { [weak self] completion in
                        guard case let .failure(failure) = completion else { return }
                        self?.logger.debug("trace identifier: \(traceIdentifier), receive failure: \(failure) for date: \(dateString)")
                    }
                )
                .eraseToAnyPublisher()
        }
    }
}
