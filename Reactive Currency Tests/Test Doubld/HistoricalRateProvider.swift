import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        // MARK: - initializer
        init() {
            dateStringAndSubjectDictionary = [:]
        }
        
        // MARK: - private property
        private var dateStringAndSubjectDictionary: [String: PassthroughSubject<ResponseDataModel.HistoricalRate, Error>]
        
        // MARK: - instance method
        func publisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> {
            let subject: PassthroughSubject<ResponseDataModel.HistoricalRate, Error> = PassthroughSubject<ResponseDataModel.HistoricalRate, Error>()
            
            dateStringAndSubjectDictionary[dateString] = subject
            return subject.eraseToAnyPublisher()
        }
        
        func publish(_ output: ResponseDataModel.HistoricalRate, for dateString: String) {
            dateStringAndSubjectDictionary[dateString]?.send(output)
        }
        
        func publish(completion: Subscribers.Completion<Error>, for dateString: String) {
            dateStringAndSubjectDictionary.removeValue(forKey: dateString)?.send(completion: completion)
        }
    }
}
