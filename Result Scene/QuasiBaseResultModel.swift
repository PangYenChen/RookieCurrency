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
        currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
        latestRate: ResponseDataModel.LatestRate,
        historicalRateSet: Set<ResponseDataModel.HistoricalRate>,
        baseCurrencyCode: ResponseDataModel.CurrencyCode,
        currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared
    ) -> [ResponseDataModel.CurrencyCode: Result<Analysis.Success, Analysis.Failure>] {
        // 計算平均值
        var meanResultDictionary: [ResponseDataModel.CurrencyCode: Result<Decimal, Analysis.Failure>] = [:]
        
        // TODO: 好醜想重寫，不用擔心會改壞，已經有unit test了。
    outer: for currencyCode in currencyCodeOfInterest {
        var mean: Decimal = 0
        for historicalRate in historicalRateSet {
            let rateConverter: RateConverter = RateConverter(rate: historicalRate, baseCurrencyCode: baseCurrencyCode)
            
            if let convertedHistoricalRateForCurrencyCode = rateConverter[currencyCodeCode: currencyCode] {
                mean += convertedHistoricalRateForCurrencyCode
            }
            else {
                meanResultDictionary[currencyCode] = .failure(.dataAbsent)
                continue outer
            }
        }
        mean /= Decimal(historicalRateSet.count)
        meanResultDictionary[currencyCode] = .success(mean)
    }
        
        // 計算偏差
        var resultDictionary: [ResponseDataModel.CurrencyCode: Result<Analysis.Success, Analysis.Failure>] = [:]
        
        for (currencyCode, meanResult) in meanResultDictionary {
            resultDictionary[currencyCode] = meanResult.flatMap { mean in
                let rateConverter: RateConverter = RateConverter(rate: latestRate, baseCurrencyCode: baseCurrencyCode)
                
                if let convertedLatestRateForCurrencyCode = rateConverter[currencyCodeCode: currencyCode] {
                    let deviation = (convertedLatestRateForCurrencyCode - mean) / mean

                    return .success(Analysis.Success(currencyCode: currencyCode,
                                                     localizedString: currencyDescriber.localizedStringFor(currencyCode: currencyCode),
                                                     latest: convertedLatestRateForCurrencyCode,
                                                     mean: mean,
                                                     deviation: deviation))
                }
                else {
                    return .failure(.dataAbsent)
                }
            }
        }
        
        return resultDictionary
        
        // 基準貨幣的換算，api 的資料邏輯是「一單位的基準貨幣等於多少單位的其他貨幣」，app 的邏輯是「一單位的其他貨幣等於多少單位的基準貨幣」。
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
            
            subscript(currencyCodeCode currencyCodeCode: ResponseDataModel.CurrencyCode) -> Decimal? {
                guard let rateForBaseCurrencyCode = rate[currencyCode: baseCurrencyCode],
                      let rateForCurrencyCode = rate[currencyCode: currencyCodeCode] else { return nil }
                
                return rateForBaseCurrencyCode / rateForCurrencyCode
            }
        }
    }
    
    /// 這個 method 是給兩個 target 的 subclass 使用的，不寫成 instance method 的原因是，
    /// reactive target 的 subclass 在 initialization 的 phase 1 中使用，所以必須獨立於 instance。
    /// 這個 method 是 pure function，所以不寫成 instance 的 dependency 也沒關係。
    static func sort(_ analysisSuccesses: [Analysis.Success],
                     by order: Order,
                     filteredIfNeededBy searchText: String?,
                     currencyDescriber: CurrencyDescriberProtocol = SupportedCurrencyManager.shared) -> [Analysis.Success] {
        analysisSuccesses
            .sorted { lhs, rhs in
                switch order {
                    case .increasing: lhs.deviation < rhs.deviation
                    case .decreasing: lhs.deviation > rhs.deviation
                }
            }
            .filter { analysisSuccess in
                guard let searchText, !searchText.isEmpty else { return true }
                
                return [analysisSuccess.currencyCode,
                        currencyDescriber.localizedStringFor(currencyCode: analysisSuccess.currencyCode)]
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
    
    /// 分析的 name space
    enum Analysis {
        typealias Result = Swift.Result<Success, Failure>
        
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
        
        enum Failure: Error {
            case dataAbsent
        }
    }
    
    enum RefreshStatus {
        case process
        case idle(latestUpdateTimestamp: Int?)
    }
}
