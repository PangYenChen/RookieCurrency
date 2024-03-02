import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif

final class QuasiBaseResultModelTests: XCTestCase {
    /// 測試一切正常運作的 test method
    func testSimpleAnalyze() throws {
        // arrange
        
        // 使用的 currency of interest 就是強勢貨幣，但就這個 test method 的測試目的來說，只要 currency of interest 包含於測試資料中即可
        let currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "USD"
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        
        // act
        let analyzedData: [ResponseDataModel.CurrencyCode: Result<QuasiBaseResultModel.Analysis.Success, QuasiBaseResultModel.Analysis.Failure>] = QuasiBaseResultModel
            .analyze(currencyCodeOfInterest: currencyCodeOfInterest,
                     latestRate: latestRate,
                     historicalRateSet: [historicalRate],
                     baseCurrencyCode: baseCurrencyCode,
                     currencyDescriber: currencyDescriberStub)
        
        // assert
        // 檢查回傳資料沒有遺漏
        XCTAssertEqual(Set(analyzedData.keys), currencyCodeOfInterest)
        
        // 每個 currency 都成功分析
        let isAnalyzedDataContainsFailure: Bool = analyzedData.values
            .contains { result in
                switch result {
                    case .success: return false
                    case .failure: return true
                }
            }
        
        XCTAssertFalse(isAnalyzedDataContainsFailure)
        
        let analyzedResultRelativeToUSD: Result<QuasiBaseResultModel.Analysis.Success, QuasiBaseResultModel.Analysis.Failure> = try XCTUnwrap(analyzedData["USD"])
        let analyzedDataRelativeToUSD: QuasiBaseResultModel.Analysis.Success = try analyzedResultRelativeToUSD.get()
        
        // 美金同時是 base currency 也是 currency of interest 時會有的性質
        XCTAssertEqual(analyzedDataRelativeToUSD.latest, 1)
        XCTAssertEqual(analyzedDataRelativeToUSD.mean, 1)
        XCTAssertEqual(analyzedDataRelativeToUSD.deviation, 0)
    }
    
    func testHistoricalRateLossACurrency() throws {
        // arrange
        let currencyLossInHistoricalRate: String = "FakeCurrencyInLatestRate"
        let currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF", currencyLossInHistoricalRate]
        
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        XCTAssertNil(historicalRate[currencyCode: currencyLossInHistoricalRate])
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        XCTAssertNotNil(latestRate[currencyCode: currencyLossInHistoricalRate])
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "USD"
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        
        // act
        var analyzedData: [ResponseDataModel.CurrencyCode: Result<QuasiBaseResultModel.Analysis.Success, QuasiBaseResultModel.Analysis.Failure>] = QuasiBaseResultModel
            .analyze(currencyCodeOfInterest: currencyCodeOfInterest,
                     latestRate: latestRate,
                     historicalRateSet: [historicalRate],
                     baseCurrencyCode: baseCurrencyCode,
                     currencyDescriber: currencyDescriberStub)
        
        // assert
        // 檢查 currencyLossInHistoricalRate 確實分析失敗
        let analyzedResultForLossCurrency: Result<QuasiBaseResultModel.Analysis.Success, QuasiBaseResultModel.Analysis.Failure> = try XCTUnwrap(analyzedData.removeValue(forKey: currencyLossInHistoricalRate))
        
        switch analyzedResultForLossCurrency {
            case .success: XCTFail("不應該是 success，這表示測試資料安排錯了。")
            case .failure: break
        }
    }
    
    func testLatestRateLossACurrency() throws {
        // arrange
        let currencyLossInLatestRate: String = "FakeCurrencyInHistoricalRate"
        let currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF", currencyLossInLatestRate]
        
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        XCTAssertNotNil(historicalRate[currencyCode: currencyLossInLatestRate])
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        XCTAssertNil(latestRate[currencyCode: currencyLossInLatestRate])
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "USD"
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        
        // act
        var analyzedData: [ResponseDataModel.CurrencyCode: Result<QuasiBaseResultModel.Analysis.Success, QuasiBaseResultModel.Analysis.Failure>] = QuasiBaseResultModel
            .analyze(currencyCodeOfInterest: currencyCodeOfInterest,
                     latestRate: latestRate,
                     historicalRateSet: [historicalRate],
                     baseCurrencyCode: baseCurrencyCode,
                     currencyDescriber: currencyDescriberStub)
        
        // assert
        // 檢查 currencyLossInLatestRate 確實分析失敗
        let analyzedResultForLossCurrency: Result<QuasiBaseResultModel.Analysis.Success, QuasiBaseResultModel.Analysis.Failure> = try XCTUnwrap(analyzedData.removeValue(forKey: currencyLossInLatestRate))
        
        switch analyzedResultForLossCurrency {
            case .success: XCTFail("不應該是 success，這表示測試資料安排錯了。")
            case .failure: break
        }
    }
}
