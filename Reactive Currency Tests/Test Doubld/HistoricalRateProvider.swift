import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        // MARK: - initializer
        init() {
            passthroughSubject = PassthroughSubject<ResponseDataModel.HistoricalRate, Error>()
        }
        
        // MARK: - private property
        private let passthroughSubject: PassthroughSubject<ResponseDataModel.HistoricalRate, Error>
        
        // MARK: - instance method
        func publisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> {
            passthroughSubject.eraseToAnyPublisher()
        }
        
        func publish(_ output: ResponseDataModel.HistoricalRate) {
            passthroughSubject.send(output)
        }
        
        func publish(completion: Subscribers.Completion<Error>) {
            passthroughSubject.send(completion: completion)
        }
    }
}
