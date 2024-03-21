import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

/// 這個 test case 測試 data model 是否正確對應到伺服器提供的 json
final class ResponseDataModelTest: XCTestCase {
    /// 測試將 json decode 成 historical rate
    func testDecodeHistoricalRate() throws {
        // arrange
        let dateString: String = "1970-01-01"
        let historicalData: Data = try XCTUnwrap(TestingData.TestingData.historicalRateDataFor(dateString: dateString))
        
        // act
        let historicalRate: ResponseDataModel.HistoricalRate = try ResponseDataModel.jsonDecoder
            .decode(ResponseDataModel.HistoricalRate.self,
                    from: historicalData)
        
        // assert
        XCTAssertEqual(historicalRate.dateString, dateString)
        XCTAssertFalse(historicalRate.rates.isEmpty)
    }
    
    /// 測試將 json decode 成 latest rate
    func testDecodeLatestRate() throws {
        // arrange
        let latestData: Data = try XCTUnwrap(TestingData.TestingData.latestData)

        // act // TODO: 這邊好像怪怪的
        let historicalRate: ResponseDataModel.LatestRate = try ResponseDataModel.jsonDecoder
            .decode(ResponseDataModel.LatestRate.self,
                    from: latestData)
        
        // assert
        XCTAssertFalse(historicalRate.rates.isEmpty)
    }
    
    /// 先將 historical rate encode 再 decode，檢查前後是否一致
    func testEncodeAndThanDecode() throws {
        // arrange
        let dateString: String = "1970-01-01"
        let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dateString)
        
        // act
        let historicalRateData: Data = try ResponseDataModel.jsonEncoder.encode(dummyHistoricalRate)
        let decodedHistoricalRate: ResponseDataModel.HistoricalRate = try ResponseDataModel.jsonDecoder
            .decode(ResponseDataModel.HistoricalRate.self, from: historicalRateData)
        
        // assert
        XCTAssertEqual(dummyHistoricalRate, decodedHistoricalRate)
        XCTAssertEqual(dummyHistoricalRate.rates, decodedHistoricalRate.rates)
        XCTAssertEqual(dummyHistoricalRate.timestamp, decodedHistoricalRate.timestamp)
    }
}
