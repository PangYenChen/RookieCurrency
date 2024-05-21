import Combine

protocol RateManagerProtocol {
    func ratePublisher(numberOfDays: Int)
    -> AnyPublisher<BaseRateManager.RateTuple, Error>
}
