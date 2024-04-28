import Foundation

protocol RateManagerProtocol {
    func getRateFor(
        numberOfDays: Int,
        completionHandlerQueue: DispatchQueue,
        completionHandler: @escaping BaseRateManager.CompletionHandler
    )
}

class RateManager: BaseRateManager, RateManagerProtocol {
    func getRateFor(numberOfDays: Int,
                    completionHandlerQueue: DispatchQueue,
                    completionHandler: @escaping CompletionHandler) {
        getRateFor(numberOfDays: numberOfDays,
                   from: Date.now,
                   completionHandlerQueue: completionHandlerQueue,
                   completionHandler: completionHandler)
    }
    
    // the purpose of this method is to
    // inject the starting date when
    // testing getRateFor(numberOfDays:completionHandlerQueue:completionHandler:)
    func getRateFor(numberOfDays: Int,
                    from start: Date,
                    completionHandlerQueue: DispatchQueue,
                    completionHandler: @escaping CompletionHandler) {
        let dispatchGroup: DispatchGroup = DispatchGroup()
        var historicalRateSetResult: Result<Set<ResponseDataModel.HistoricalRate>, Error>?
        var latestRateResult: Result<ResponseDataModel.LatestRate, Error>?
        let serialDispatchQueue: DispatchQueue = DispatchQueue(label: "rate.manager")
        
        do /*request historical rate set*/ {
            historicalRateDateStrings(numberOfDaysAgo: numberOfDays, from: start)
                .forEach { historicalRateDateString in
                    dispatchGroup.enter()
                    
                    historicalRateProvider.historicalRateFor(dateString: historicalRateDateString) { result in
                        serialDispatchQueue.async {
                            let latestRateHasFailed: Bool = switch latestRateResult {
                            case .success: false
                            case .failure: true
                            case nil: false
                            }
                            
                            guard !latestRateHasFailed else { return }
                            
                            switch historicalRateSetResult {
                                case .success(let historicalRateSet):
                                    switch result {
                                        case .success(let historicalRate):
                                            historicalRateSetResult = .success(historicalRateSet.union([historicalRate]))
                                        case .failure(let error):
                                            historicalRateSetResult = .failure(error)
                                            completionHandlerQueue.async { completionHandler(.failure(error)) }
                                    }
                                case .failure:
                                    break
                                case nil:
                                    switch result {
                                        case .success(let historicalRate):
                                            historicalRateSetResult = .success([historicalRate])
                                        case .failure(let error):
                                            historicalRateSetResult = .failure(error)
                                            completionHandlerQueue.async { completionHandler(.failure(error)) }
                                    }
                            }
                            
                            dispatchGroup.leave()
                        }
                    }
                }
        }
        
        do /*request latest rate*/ {
            dispatchGroup.enter()
            
            latestRateProvider.latestRate { result in
                let hasHistoricalRateSetFailed: Bool = switch historicalRateSetResult {
                case .success: false
                case .failure: true
                case nil: false
                }
                
                guard !hasHistoricalRateSetFailed else { return }
                
                switch result {
                    case .success(let latestRate):
                        latestRateResult = .success(latestRate)
                    case .failure(let failure):
                        latestRateResult = .failure(failure)
                        completionHandlerQueue.async { completionHandler(.failure(failure)) }
                }
                
                dispatchGroup.leave()
            }
        }
        
        // all enters have been set synchronously
        dispatchGroup.notify(queue: completionHandlerQueue) {
            guard let historicalRateSetResult,
                  let latestRateResult else {
                assertionFailure("historicalRateSetResult 跟 latestRateResult 都有值之後才會執行到此")
                return
            }
            
            guard let historicalRateSet = try? historicalRateSetResult.get(),
                  let latestRate = try? latestRateResult.get() else {
                // resulting in failure has been handled.
                return
            }
            
            completionHandler(.success((latestRate: latestRate,
                                        historicalRateSet: historicalRateSet)))
        }
    }
}

// MARK: - name space
extension BaseRateManager {
    typealias CompletionHandler = (_ result: Result<RateTuple, Error>) -> Void
}
