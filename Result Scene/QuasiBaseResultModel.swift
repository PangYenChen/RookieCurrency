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
    static func analyze(
        baseCurrencyCode: ResponseDataModel.CurrencyCode,
        currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
        latestRate: ResponseDataModel.LatestRate,
        historicalRateSet: Set<ResponseDataModel.HistoricalRate>,
        currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared
    ) -> Analysis {
        var successes: Set<Analysis.Success> = []
        var dataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode> = []
        
    loop: // 這邊刻意不用 functional 的方式寫，因為 currency code 的數量可以很多，number of days 也可以很的，要儘早 continue
        for currencyCode in currencyCodeOfInterest {
            // 計算 mean
            var mean: Decimal = 0
            for historicalRate in historicalRateSet {
                let rateConverter: RateConverter = RateConverter(rate: historicalRate, baseCurrencyCode: baseCurrencyCode)
                
                if let convertedHistoricalRateForCurrencyCode = rateConverter[currencyCode: currencyCode] {
                    mean += convertedHistoricalRateForCurrencyCode
                }
                else {
                    dataAbsentCurrencyCodeSet.insert(currencyCode)
                    continue loop
                }
            }
            mean /= Decimal(historicalRateSet.count)
            
            // 計算 deviation
            let rateConverter: RateConverter = RateConverter(rate: latestRate, baseCurrencyCode: baseCurrencyCode)
            
            if let convertedLatestRateForCurrencyCode = rateConverter[currencyCode: currencyCode] {
                let deviation: Decimal = (convertedLatestRateForCurrencyCode - mean) / mean
                
                successes.insert(Analysis.Success(
                    currencyCode: currencyCode,
                    localizedString: currencyDescriber.localizedStringFor(currencyCode: currencyCode),
                    latest: convertedLatestRateForCurrencyCode,
                    mean: mean,
                    deviation: deviation
                ))
            }
            else {
                dataAbsentCurrencyCodeSet.insert(currencyCode)
                continue loop
            }
        }
        
        return Analysis(successes: successes, dataAbsentCurrencyCodeSet: dataAbsentCurrencyCodeSet)
        
        // 基準貨幣的換算，api 的資料邏輯是「一單位的基準貨幣等於多少單位的其他貨幣」，app 的邏輯是「一單位的其他貨幣等於多少單位的基準貨幣」。
        // TODO: 這個看要不要寫在 response model 裡面，或者在進來之前轉好，不然這邊的邏輯有點多
        struct RateConverter<Category> where Category: RateCategoryProtocol {
            typealias Rate = ResponseDataModel.Rate<Category>
            
            private let rate: Rate
            
            private let baseCurrencyCode: ResponseDataModel.CurrencyCode
            
            init(
                rate: Rate,
                baseCurrencyCode: ResponseDataModel.CurrencyCode
            ) {
                self.rate = rate
                self.baseCurrencyCode = baseCurrencyCode
            }
            
            subscript(currencyCode currencyCode: ResponseDataModel.CurrencyCode) -> Decimal? {
                guard let rateForBaseCurrencyCode = rate[currencyCode: baseCurrencyCode],
                      let rateForCurrencyCode = rate[currencyCode: currencyCode] else { return nil }
                
                return rateForBaseCurrencyCode / rateForCurrencyCode
            }
        }
    }
    
    /// 這個 method 是給兩個 target 的 subclass 使用的，不寫成 instance method 的原因是，
    /// reactive target 的 subclass 在 initialization 的 phase 1 中使用，所以必須獨立於 instance。
    /// 這個 method 是 pure function，所以不寫成 instance 的 dependency 也沒關係。
    static func sort(_ successes: Set<Analysis.Success>,
                     by order: Order,
                     filteredIfNeededBy searchText: String?) -> [Analysis.Success] {
        successes
            .sorted { lhs, rhs in
                switch order {
                    case .increasing: lhs.deviation < rhs.deviation
                    case .decreasing: lhs.deviation > rhs.deviation
                }
            }
            .filter { analysisSuccess in
                guard let searchText, !searchText.isEmpty else { return true }
                
                return [analysisSuccess.currencyCode,
                        analysisSuccess.localizedString]
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
        
        var localizedName: String {
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
    
    struct Analysis {
        let successes: Set<Analysis.Success>
        let dataAbsentCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode>
        
        struct Success: Hashable {
            let currencyCode: ResponseDataModel.CurrencyCode
            let localizedString: String
            let latest: Decimal
            let mean: Decimal
            let deviation: Decimal
            
            func hash(into hasher: inout Hasher) {
                hasher.combine(currencyCode)
            }
            
            static func == (lhs: Self, rhs: Self) -> Bool {
                lhs.currencyCode == rhs.currencyCode
            }
        }
    }
    
    enum RefreshStatus {
        case process
        case idle(latestUpdateTimestamp: Int?)
    }
}
