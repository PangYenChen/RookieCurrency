import Foundation

protocol RateManagerProtocol {
    func getRateFor(
        numberOfDays: Int,
        completionHandlerQueue: DispatchQueue,
        completionHandler: @escaping BaseRateManager.CompletionHandler
    )
}

// TODO: 這裡的 method 好長 看能不能拆開"
class RateManager: BaseRateManager, RateManagerProtocol {
    func getRateFor(
        numberOfDays: Int,
        completionHandlerQueue: DispatchQueue,
        completionHandler: @escaping CompletionHandler) {
        getRateFor(numberOfDays: numberOfDays,
                   from: Date.now,
                   completionHandlerQueue: completionHandlerQueue,
                   completionHandler: completionHandler)
    }
    
    func getRateFor(
        numberOfDays: Int,
        from start: Date,
        completionHandlerQueue: DispatchQueue,
        completionHandler: @escaping CompletionHandler
    ) {
        var historicalRateSetResult: Result<Set<ResponseDataModel.HistoricalRate>, Error>?
        
        let dispatchGroup: DispatchGroup = DispatchGroup() // TODO: 試試看全部都從cache來會不會crash
        
        historicalRateDateStrings(numberOfDaysAgo: numberOfDays, from: start)
            .forEach { historicalRateDateString in
                dispatchGroup.enter()
                
                historicalRateProvider.historicalRateFor(dateString: historicalRateDateString) { [unowned self] result in
                    switch result {
                        case .success(let historicalRate):
                            concurrentQueue.async(flags: .barrier) {
                                historicalRateSetResult = historicalRateSetResult ?? .success([])
                                    .map { historicalRateSet in historicalRateSet.union([historicalRate]) }
                                
                                dispatchGroup.leave()
                            }
                            
                        case .failure(let failure):
                            concurrentQueue.async(flags: .barrier) {
                                historicalRateSetResult = .failure(failure)
                                
                                dispatchGroup.leave()
                            }
                    }
                }
            }
        
        var latestRateResult: Result<ResponseDataModel.LatestRate, Error>?
        
        dispatchGroup.enter()
        
        fetcher.fetch(Endpoints.Latest()) { result in
            latestRateResult = result
        
            dispatchGroup.leave()
        }
        
        // all enters have been set synchronously
        dispatchGroup.notify(queue: completionHandlerQueue) {
            do {
                guard let historicalRateSetResult,
                      let latestRateResult else {
                    assertionFailure("###, \(#function), \(self), 使用 dispatch group 的方式錯了")
                    return
                }
                
                let historicalRateSet: Set<ResponseDataModel.HistoricalRate> = try historicalRateSetResult.get()
                let latestRate: ResponseDataModel.LatestRate = try latestRateResult.get()
                
                completionHandler(.success((latestRate: latestRate,
                                            historicalRateSet: historicalRateSet)))
            }
            catch {
                completionHandler(.failure(error))
            }
        }
    }
}

// MARK: - name space
extension BaseRateManager {
    typealias CompletionHandler = (_ result: Result<RateTuple, Error>) -> Void
}
