import Foundation

/// 從數據中分析出貨幣的升貶值的物件
enum Analyst {
    
    static func analyze(currencyOfInterest: Set<ResponseDataModel.CurrencyCode>,
                        latestRate: ResponseDataModel.LatestRate,
                        historicalRateSet: Set<ResponseDataModel.HistoricalRate>,
                        baseCurrency: ResponseDataModel.CurrencyCode)
    -> [ResponseDataModel.CurrencyCode: Result<AnalyzedData, AnalyzedError>] {
        
        // 計算平均值
        var meanResultDictionary: [ResponseDataModel.CurrencyCode: Result<Decimal, AnalyzedError>] = [:]
        // TODO: 好醜想重寫，不用擔心會改壞，已經有unit test了。
    outer: for currencyCode in currencyOfInterest {
        var mean: Decimal = 0
        for historicalRate in historicalRateSet {
            
            let rateConverter = RateConverter(rate: historicalRate, baseCurrency: baseCurrency)
            
            if let convertedHistoricalRateForCurrencyCode = rateConverter[currencyCode: currencyCode] {
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
        var resultDictionary: [ResponseDataModel.CurrencyCode: Result<AnalyzedData, AnalyzedError>] = [:]
        
        for (currencyCode, meanResult) in meanResultDictionary {
            resultDictionary[currencyCode] = meanResult.flatMap { mean in
                let rateConverter = RateConverter(rate: latestRate, baseCurrency: baseCurrency)
                
                if let convertedLatestRateForCurrencyCode = rateConverter[currencyCode: currencyCode] {
                    let deviation = (convertedLatestRateForCurrencyCode - mean) / mean
                    return .success((latest: convertedLatestRateForCurrencyCode, mean: mean, deviation: deviation))
                }
                else {
                    return .failure(.dataAbsent)
                }
            }
        }
        
        return resultDictionary
    }
}

// MARK: - name space
extension Analyst {
    typealias AnalyzedData = (latest: Decimal, mean: Decimal, deviation: Decimal)
    
    enum AnalyzedError: Error {
        case dataAbsent
    }
    
    // 基準貨幣的換算，api 的資料邏輯是「一單位的基準貨幣等於多少單位的其他貨幣」，app 的邏輯是「一單位的其他貨幣等於多少單位的基準貨幣」。
    private struct RateConverter<Category> where Category: RateCategoryProtocol {
        typealias Rate = ResponseDataModel.Rate<Category>
        
        private let rate: Rate
        
        private let baseCurrency: ResponseDataModel.CurrencyCode
        
        init(rate: Rate,
             baseCurrency: ResponseDataModel.CurrencyCode) {
            self.rate = rate
            self.baseCurrency = baseCurrency
        }
        
        subscript(currencyCode currencyCode: ResponseDataModel.CurrencyCode) -> Decimal? {
            guard let rateForBaseCurrency = rate[currencyCode: baseCurrency],
                  let rateForCurrency = rate[currencyCode: currencyCode] else { return nil }
            
            return rateForBaseCurrency / rateForCurrency
        }
    }
}
