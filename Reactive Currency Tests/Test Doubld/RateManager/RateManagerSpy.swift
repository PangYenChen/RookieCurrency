import Foundation
import Combine

@testable import ReactiveCurrency

class RateManagerSpy: RateManagerProtocol {
    var numberOfDays: Int?
    
    var result: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>
    
    init(result: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error>) {
        self.numberOfDays = nil
        self.result = result
    }
    
    func ratePublisher(numberOfDays: Int) -> AnyPublisher<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> {
        self.numberOfDays = numberOfDays
        return result.publisher.eraseToAnyPublisher()
    }
}
