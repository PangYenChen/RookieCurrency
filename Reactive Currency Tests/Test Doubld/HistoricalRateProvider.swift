import Foundation
import Combine

@testable import ReactiveCurrency

extension TestDouble {
    class HistoricalRateProvider: HistoricalRateProviderProtocol {
        init() {
            dateStringAndSubjectDictionary = [:]
        }
        
        private(set) var dateStringAndSubjectDictionary: [String: PassthroughSubject<ResponseDataModel.HistoricalRate, Error>]
        
        func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error> {
            let subject: PassthroughSubject<ResponseDataModel.HistoricalRate, Error> = PassthroughSubject<ResponseDataModel.HistoricalRate, Error>()
            
            dateStringAndSubjectDictionary[dateString] = subject
            return subject.eraseToAnyPublisher()
        }
        
        func removeAllStorage() {
            dateStringAndSubjectDictionary.removeAll()
        }
        
        func publish(_ output: ResponseDataModel.HistoricalRate, for dateString: String) {
            dateStringAndSubjectDictionary[dateString]?.send(output)
        }
        
        func publish(completion: Subscribers.Completion<Error>, for dateString: String) {
            dateStringAndSubjectDictionary.removeValue(forKey: dateString)?.send(completion: completion)
        }
    }
}
