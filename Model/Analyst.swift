import Foundation

/// 從數據中分析出貨幣的升貶值的物件
enum Analyst {
    
    static func analyze(currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>,
                        latestRate: ResponseDataModel.LatestRate,
                        historicalRateSet: Set<ResponseDataModel.HistoricalRate>,
                        baseCurrencyCode: ResponseDataModel.CurrencyCode)
    -> [ResponseDataModel.CurrencyCode: Result<AnalyzedData, AnalyzedError>] {
        
        // 計算平均值
        var meanResultDictionary: [ResponseDataModel.CurrencyCode: Result<Decimal, AnalyzedError>] = [:]
        // TODO: 好醜想重寫，不用擔心會改壞，已經有unit test了。
    outer: for currencyCode in currencyCodeOfInterest {
        var mean: Decimal = 0
        for historicalRate in historicalRateSet {
            
            let rateConverter = RateConverter(rate: historicalRate, baseCurrencyCode: baseCurrencyCode)
            
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
        var resultDictionary: [ResponseDataModel.CurrencyCode: Result<AnalyzedData, AnalyzedError>] = [:]
        
        for (currencyCode, meanResult) in meanResultDictionary {
            resultDictionary[currencyCode] = meanResult.flatMap { mean in
                let rateConverter = RateConverter(rate: latestRate, baseCurrencyCode: baseCurrencyCode)
                
                if let convertedLatestRateForCurrencyCode = rateConverter[currencyCodeCode: currencyCode] {
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
        
        private let baseCurrencyCode: ResponseDataModel.CurrencyCode
        
        init(rate: Rate,
             baseCurrencyCode: ResponseDataModel.CurrencyCode) {
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
