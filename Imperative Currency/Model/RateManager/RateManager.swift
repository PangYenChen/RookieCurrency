import Foundation

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
        let id: String = UUID().uuidString
        logger.debug("start requesting rate for number of days: \(numberOfDays) from: \(start) with id: \(id)")
        
        let dispatchGroup: DispatchGroup = DispatchGroup()
        var historicalRateSetResult: Result<Set<ResponseDataModel.HistoricalRate>, Error>?
        let serialDispatchQueue: DispatchQueue = DispatchQueue(label: "rate.manager")
        
        do /*request historical rate set*/ {
            dispatchGroup.enter()
            
            historicalRateSet(numberOfDaysAgo: numberOfDays, from: start) { [unowned self] result in
                serialDispatchQueue.async {
                    switch result {
                        case .success(let historicalRateSet):
                            historicalRateSetResult = .success(historicalRateSet)
                        case .failure(let failure):
                            historicalRateSetResult = .failure(failure)
                            logger.debug("receive failure: \(failure) for historical rate and number of days: \(numberOfDays) from: \(start) with id: \(id)")
                            completionHandlerQueue.async { completionHandler(.failure(failure)) }
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        var latestRateResult: Result<ResponseDataModel.LatestRate, Error>?
        
        do /*request latest rate*/ {
            dispatchGroup.enter()
            
            latestRateProvider.latestRate { [unowned self] result in
                switch result {
                    case .success(let latestRate):
                        latestRateResult = .success(latestRate)
                    case .failure(let failure):
                        latestRateResult = .failure(failure)
                        logger.debug("receive failure: \(failure) for latest rate and number of days: \(numberOfDays) from: \(start) with id: \(id)")
                        completionHandlerQueue.async { completionHandler(.failure(failure)) }
                }
                
                dispatchGroup.leave()
            }
        }
        
        // all enters have been set synchronously
        dispatchGroup.notify(queue: completionHandlerQueue) { [unowned self] in
            guard let historicalRateSetResult,
                  let latestRateResult else {
                assertionFailure("historicalRateSetResult 跟 latestRateResult 該有值卻沒值")
                return
            }
            
            guard let historicalRateSet = try? historicalRateSetResult.get(),
                  let latestRate = try? latestRateResult.get() else {
                // resulting in failure has been handled.
                return
            }
            logger.debug("receive rate tuple for number of days: \(numberOfDays) from: \(start) with id: \(id)")
            
            completionHandlerQueue.async { completionHandler(.success((latestRate: latestRate,
                                                                       historicalRateSet: historicalRateSet))) }
        }
    }
    
    func historicalRateSet(
        numberOfDaysAgo: Int,
        from start: Date,
        completionHandler: @escaping (Result<Set<ResponseDataModel.HistoricalRate>, Error>) -> Void
    ) {
        let dispatchGroup: DispatchGroup = DispatchGroup()
        var historicalRateSetResult: Result<Set<ResponseDataModel.HistoricalRate>, Error>?
        let serialDispatchQueue: DispatchQueue = DispatchQueue(label: "historical.rate.set")
        
        historicalRateDateStrings(numberOfDaysAgo: numberOfDaysAgo, from: start)
            .forEach { historicalRateDateString in
                dispatchGroup.enter()
                
                historicalRateProvider.historicalRateFor(dateString: historicalRateDateString) { result in
                    serialDispatchQueue.async {
                        switch historicalRateSetResult {
                            case .success(let historicalRateSet):
                                switch result {
                                    case .success(let historicalRate):
                                        historicalRateSetResult = .success(historicalRateSet.union([historicalRate]))
                                    case .failure(let error):
                                        historicalRateSetResult = .failure(error)
                                        completionHandler(.failure(error))
                                }
                            case .failure:
                                break
                            case nil:
                                switch result {
                                    case .success(let historicalRate):
                                        historicalRateSetResult = .success([historicalRate])
                                    case .failure(let error):
                                        historicalRateSetResult = .failure(error)
                                        completionHandler(.failure(error))
                                }
                        }
                        
                        dispatchGroup.leave()
                    }
                }
            }
        
        dispatchGroup.notify(queue: serialDispatchQueue) {
            guard let historicalRateSetResult else {
                assertionFailure("應該要全部的 historical rate result 都有結果才能執行到這邊")
                return
            }
            
            switch historicalRateSetResult {
                case .success(let historicalRateSet): completionHandler(.success(historicalRateSet))
                case .failure: break
            }
        }
    }
}

// MARK: - name space
extension BaseRateManager {
    typealias CompletionHandler = (_ result: Result<RateTuple, Error>) -> Void
}
