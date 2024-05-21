import Foundation

protocol RateManagerProtocol {
    func getRateFor(
        numberOfDays: Int,
        completionHandlerQueue: DispatchQueue,
        completionHandler: @escaping BaseRateManager.CompletionHandler
    )
}
