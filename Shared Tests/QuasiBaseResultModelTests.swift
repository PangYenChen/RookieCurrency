import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif

// this test case only tests `QuasiBaseResultModel`'s static method
// instance behaviors are tested in other test cases.
final class QuasiBaseResultModelTests: XCTestCase {
    private let sut: QuasiBaseResultModel.Type = QuasiBaseResultModel.self
    
    func testStatisticize() throws {
        // arrange
        
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
        
        let supportedCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
        let nonSupportedCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode> = ["FakeCurrencyInHistoricalRate"]
        let currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = supportedCurrencyCodeSet.union(nonSupportedCurrencyCodeSet)
        
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        
        // act
        let statisticsResult: QuasiBaseResultModel.StatisticsInfo = sut.statisticize(baseCurrencyCode: baseCurrencyCode,
                                                currencyCodeOfInterest: currencyCodeOfInterest,
                                                latestRate: latestRate,
                                                historicalRateSet: [historicalRate],
                                                currencyDescriber: currencyDescriberStub)
        
        // assert
        XCTAssertEqual(Set(statisticsResult.rateStatistics.map { $0.currencyCode }),
                       supportedCurrencyCodeSet)
        
        XCTAssertEqual(statisticsResult.dataAbsentCurrencyCodeSet, nonSupportedCurrencyCodeSet)
    }
}
