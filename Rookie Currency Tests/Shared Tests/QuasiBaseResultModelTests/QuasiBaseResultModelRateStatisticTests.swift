import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

final class QuasiBaseResultModelRateStatisticTests: XCTestCase {
    private let sut: QuasiBaseResultModel.RateStatistic.Type = QuasiBaseResultModel.RateStatistic.self
    
    func testInit() throws {
        // arrange
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
        let targetCurrencyCode: ResponseDataModel.CurrencyCode = "USD"
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        
        // act
        let rateStatistic: QuasiBaseResultModel.RateStatistic? = sut.init(baseCurrencyCode: baseCurrencyCode,
                                                                          currencyCode: targetCurrencyCode,
                                                                          currencyDescriber: currencyDescriberStub,
                                                                          latestRate: latestRate,
                                                                          historicalRateSet: [historicalRate])
        
        // assert
        XCTAssertNotNil(rateStatistic)
    }
    
    func testInitBaseCurrencyCodeNotInLatestRate() throws {
        // arrange
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "FakeCurrencyCodeInHistoricalRate"
        let targetCurrencyCode: ResponseDataModel.CurrencyCode = "USD"
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        
        // act
        let rateStatistic: QuasiBaseResultModel.RateStatistic? = sut.init(baseCurrencyCode: baseCurrencyCode,
                                                                          currencyCode: targetCurrencyCode,
                                                                          currencyDescriber: currencyDescriberStub,
                                                                          latestRate: latestRate,
                                                                          historicalRateSet: [historicalRate])
        
        // assert
        XCTAssertNil(rateStatistic)
    }
    
    func testInitTargetCurrencyCodeNotInLatestRate() throws {
        // arrange
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
        let targetCurrencyCode: ResponseDataModel.CurrencyCode = "FakeCurrencyCodeInHistoricalRate"
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        
        // act
        let rateStatistic: QuasiBaseResultModel.RateStatistic? = sut.init(baseCurrencyCode: baseCurrencyCode,
                                                                          currencyCode: targetCurrencyCode,
                                                                          currencyDescriber: currencyDescriberStub,
                                                                          latestRate: latestRate,
                                                                          historicalRateSet: [historicalRate])
        
        // assert
        XCTAssertNil(rateStatistic)
    }
    
    func testInitBaseCurrencyCodeNotInHistoricalRate() throws {
        // arrange
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "FakeCurrencyCodeInLatestRate"
        let targetCurrencyCode: ResponseDataModel.CurrencyCode = "USD"
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        
        // act
        let rateStatistic: QuasiBaseResultModel.RateStatistic? = sut.init(baseCurrencyCode: baseCurrencyCode,
                                                                          currencyCode: targetCurrencyCode,
                                                                          currencyDescriber: currencyDescriberStub,
                                                                          latestRate: latestRate,
                                                                          historicalRateSet: [historicalRate])
        
        // assert
        XCTAssertNil(rateStatistic)
    }
    
    func testInitTargetCurrencyCodeNotInHistoricalRate() throws {
        // arrange
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
        let targetCurrencyCode: ResponseDataModel.CurrencyCode = "FakeCurrencyCodeInLatestRate"
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        
        // act
        let rateStatistic: QuasiBaseResultModel.RateStatistic? = sut.init(baseCurrencyCode: baseCurrencyCode,
                                                                          currencyCode: targetCurrencyCode,
                                                                          currencyDescriber: currencyDescriberStub,
                                                                          latestRate: latestRate,
                                                                          historicalRateSet: [historicalRate])
        
        // assert
        XCTAssertNil(rateStatistic)
    }
}
