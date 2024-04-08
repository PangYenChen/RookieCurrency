import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        // MARK: - initializer
        init() {
            dateStringAndSubjectDictionary = [:]
            numberOfCallOfRemoveCachedAndStoredRate = 0
        }
        
        // MARK: - private property
        private var dateStringAndSubjectDictionary: [String: PassthroughSubject<ResponseDataModel.HistoricalRate, Error>]
        private(set) var numberOfCallOfRemoveCachedAndStoredRate: Int
        
        // MARK: - instance method
        func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> {
            let subject: PassthroughSubject<ResponseDataModel.HistoricalRate, Error> = PassthroughSubject<ResponseDataModel.HistoricalRate, Error>()
            
            dateStringAndSubjectDictionary[dateString] = subject
            return subject.eraseToAnyPublisher()
        }
        
        func removeCachedAndStoredRate() { numberOfCallOfRemoveCachedAndStoredRate += 1 }
        
        func publish(_ output: ResponseDataModel.HistoricalRate, for dateString: String) {
            dateStringAndSubjectDictionary[dateString]?.send(output)
        }
        
        func publish(completion: Subscribers.Completion<Error>, for dateString: String) {
            dateStringAndSubjectDictionary.removeValue(forKey: dateString)?.send(completion: completion)
        }
    }
}
