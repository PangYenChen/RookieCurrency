import Foundation

class QuasiBaseResultModel {
    init(currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared,
         userSettingManager: UserSettingManagerProtocol) {
        self.currencyDescriber = currencyDescriber
        initialOrder = userSettingManager.resultOrder
    }
    
    let initialOrder: Order
    
    private let currencyDescriber: CurrencyDescriberProtocol
}

// MARK: - static property
extension QuasiBaseResultModel {
    /// 這個 property 是給兩個 target 的 subclass 使用的，不寫成 instance property 的原因是，
    /// reactive target 的 subclass 在 initialization 的 phase 1 中使用，所以必須獨立於 instance。
    static let autoRefreshTimeInterval: TimeInterval = 5
}

// MARK: - static methods
extension QuasiBaseResultModel {
    /// 這個 method 是給兩個 target 的 subclass 使用的，不寫成 instance method 的原因是，
    /// reactive target 的 subclass 在 initialization 的 phase 1 中使用，所以必須獨立於 instance。
    /// 這個 method 是 pure function，所以不寫成 instance 的 dependency 也沒關係。
    static func statisticize(
        baseCurrencyCode: ResponseDataModel.CurrencyCode,
        currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
        latestRate: ResponseDataModel.LatestRate,
        historicalRateSet: Set<ResponseDataModel.HistoricalRate>,
        currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared
    ) -> StatisticsInfo {
        var rateStatistics: Set<RateStatistic> = []
        var dataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode> = []
        
        for targetCurrencyCode in currencyCodeOfInterest {
            if let rateStatic = RateStatistic(baseCurrencyCode: baseCurrencyCode,
                                              currencyCode: targetCurrencyCode,
                                              currencyDescriber: currencyDescriber,
                                              latestRate: latestRate,
                                              historicalRateSet: historicalRateSet) {
                rateStatistics.insert(rateStatic)
            }
            else {
                dataAbsentCurrencyCodeSet.insert(targetCurrencyCode)
            }
        }
        
        return (rateStatistics: rateStatistics, dataAbsentCurrencyCodeSet: dataAbsentCurrencyCodeSet)
    }
    
    /// 這個 method 是給兩個 target 的 subclass 使用的，不寫成 instance method 的原因是，
    /// reactive target 的 subclass 在 initialization 的 phase 1 中使用，所以必須獨立於 instance。
    /// 這個 method 是 pure function，所以不寫成 instance 的 dependency 也沒關係。
    static func sort(_ rateStatistics: Set<RateStatistic>,
                     by order: Order,
                     filteredIfNeededBy searchText: String?) -> [RateStatistic] {
        rateStatistics
            .sorted { lhs, rhs in
                switch order {
                    case .increasing: lhs.fluctuation < rhs.fluctuation
                    case .decreasing: lhs.fluctuation > rhs.fluctuation
                }
            }
            .filter { rateStatistic in
                guard let searchText, !searchText.isEmpty else { return true }
                
                return [rateStatistic.currencyCode,
                        rateStatistic.localizedString]
                    .compactMap { $0 }
                    .contains { text in text.localizedStandardContains(searchText) }
            }
    }
}

// MARK: - name space
extension QuasiBaseResultModel {
    /// 資料的排序方式。
    enum Order: String {
        case increasing
        case decreasing
        
        var localizedString: String {
            switch self {
                case .increasing: R.string.resultScene.increasing()
                case .decreasing: R.string.resultScene.decreasing()
            }
        }
    }
    
    /// user setting 中，order 在 result model 編輯；
    /// numberOfDays、baseCurrencyCode、currencyCodeOfInterest 在 setting model 編輯，
    /// 特地寫這個 type alias 裝這三個變數，以便傳遞。
    typealias Setting = (numberOfDays: Int,
                         baseCurrencyCode: ResponseDataModel.CurrencyCode,
                         currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>)
    
    /// 這是容納換算好的資料的容器
    struct RateStatistic: Hashable {
        let currencyCode: ResponseDataModel.CurrencyCode
        let localizedString: String
        let latestRate: Decimal
        let meanRate: Decimal
        let fluctuation: Decimal
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(currencyCode)
        }
        
        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.currencyCode == rhs.currencyCode
        }
    }
    
    typealias StatisticsInfo = (rateStatistics: Set<RateStatistic>, dataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>)
    
    enum RefreshStatus {
        case process
        case idle(latestUpdateTimestamp: Int?)
    }
}

extension QuasiBaseResultModel.RateStatistic {
    init?(baseCurrencyCode: ResponseDataModel.CurrencyCode,
          currencyCode: ResponseDataModel.CurrencyCode,
          currencyDescriber: CurrencyDescriberProtocol,
          latestRate: ResponseDataModel.LatestRate,
          historicalRateSet: Set<ResponseDataModel.HistoricalRate>) {
        self.currencyCode = currencyCode
        self.localizedString = currencyDescriber.localizedStringFor(currencyCode: currencyCode)
        
        guard let latestRate = latestRate.convertOneUnitOf(baseCurrencyCode, to: currencyCode) else { return nil }
        
        self.latestRate = latestRate
        
        var total: Decimal = 0
        for historicalRate in historicalRateSet {
            guard let historicalRate = historicalRate.convertOneUnitOf(baseCurrencyCode, to: currencyCode) else { return nil }
            
            total += historicalRate
        }
        
        meanRate = total / Decimal(historicalRateSet.count)
        
        fluctuation = (latestRate - meanRate) / meanRate
    }
}

private extension ResponseDataModel.Rate {
    /// api 的資料邏輯是「一單位的基準貨幣等於多少單位的其他貨幣」，app 的邏輯是「一單位的其他貨幣等於多少單位的基準貨幣」。
    func convertOneUnitOf(_ baseCurrencyCode: ResponseDataModel.CurrencyCode, to targetCurrencyCode: ResponseDataModel.CurrencyCode) -> Decimal? {
        guard let rateForBaseCurrencyCode = self[currencyCode: baseCurrencyCode],
              let rateForTargetCurrencyCode = self[currencyCode: targetCurrencyCode] else { return nil }
        
        return rateForBaseCurrencyCode / rateForTargetCurrencyCode
    }
}
