import Foundation
import Combine

class ResultModel: BaseResultModel {
#warning("要修改 access control")
    // MARK: - input
    let userSetting: CurrentValueSubject<BaseResultModel.UserSetting, Never>
    
    let order: AnySubscriber<Order, Never>
    
    let searchText: AnySubscriber<String?, Never>
    
    let updateState: AnySubscriber<Void, Never>
    
    // MARK: - output
    
    let state: AnyPublisher<State, Never>
    
    
#warning("還沒實作自動更新")
    
    override init() {
        userSetting = CurrentValueSubject((AppUtility.numberOfDays, AppUtility.baseCurrencyCode, AppUtility.currencyCodeOfInterest))
        
        let orderPublisher = CurrentValueSubject<BaseResultModel.Order, Never>(AppUtility.order)
        order = AnySubscriber(orderPublisher)
        
        let searchTextPublisher = CurrentValueSubject<String?, Never>(nil)
        searchText = AnySubscriber(searchTextPublisher)
        
        let updateStatePublisher = CurrentValueSubject<Void, Never>(())
        updateState = AnySubscriber(updateStatePublisher)
        
        //
        
        do {
            let fetchData = Publishers.CombineLatest(updateStatePublisher, userSetting).share()
            
            let analyzedSuccessTuple = fetchData
                .flatMap { _, userSetting in
                    RateController.shared
                        .ratePublisher(numberOfDay: userSetting.numberOfDay)
                        .convertOutputToResult()
                        .map { result in
                            result.map { rateTuple in
                                let analyzedDataArray = Analyst.analyze(currencyOfInterest: userSetting.currencyOfInterest,
                                                                        latestRate: rateTuple.latestRate,
                                                                        historicalRateSet: rateTuple.historicalRateSet,
                                                                        baseCurrency: userSetting.baseCurrency)
                                    .compactMapValues { result in try? result.get() }
                                    .map { tuple in
                                        AnalyzedData(currencyCode: tuple.key, latest: tuple.value.latest, mean: tuple.value.mean, deviation: tuple.value.deviation)
                                    }
                                return (latestUpdateTime: rateTuple.latestRate.timestamp, analyzedDataArray: analyzedDataArray)
                            }
                        }
                        
                }
                .resultSuccess()
#warning("還沒處理錯誤，要提示使用者即將刪掉本地的資料，重新從網路上拿")
            
                        
            let orderAndSearchText = Publishers.CombineLatest(orderPublisher.print("#####"), searchTextPublisher)
                .map { (order: $0, searchText: $1) }
                
            
            state = Publishers.CombineLatest(analyzedSuccessTuple, orderAndSearchText)
                .map { analyzedSuccessTuple, orderAndSearchText in
                    let analyzedDataArray = Self.sort(analyzedSuccessTuple.analyzedDataArray,
                                                      by: orderAndSearchText.order,
                                                      filteredIfNeededBy: orderAndSearchText.searchText)
                    return State.updated(timestamp: analyzedSuccessTuple.latestUpdateTime,
                                         analyzedDataArray: analyzedDataArray)
                }
                .eraseToAnyPublisher()
        }
        
        super.init()
        
#warning("要存 app utility")
        
    }
}
