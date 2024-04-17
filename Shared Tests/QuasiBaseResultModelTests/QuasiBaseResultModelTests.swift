import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

// this test case only tests `QuasiBaseResultModel`'s static method
// instance behaviors are tested in other test cases.
final class QuasiBaseResultModelTests: XCTestCase {
    private let sut: QuasiBaseResultModel.Type = QuasiBaseResultModel.self
    
    func testStatisticize() throws {
        // arrange
        
        let baseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
        
        let supportedCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
        let nonSupportedCurrencyCodeSet: Set<ResponseDataModel.CurrencyCode> = ["FakeCurrencyCodeInHistoricalRate"]
        let currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = supportedCurrencyCodeSet.union(nonSupportedCurrencyCodeSet)
        
        let latestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
        let dummyDateString: String = "1970-01-01"
        let historicalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: dummyDateString)
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        
        // act
        let statisticsResult: QuasiBaseResultModel.StatisticsInfo = sut
            .statisticize(baseCurrencyCode: baseCurrencyCode,
                          currencyCodeOfInterest: currencyCodeOfInterest,
                          latestRate: latestRate,
                          historicalRateSet: [historicalRate],
                          currencyDescriber: currencyDescriberStub)
        
        // assert
        XCTAssertEqual(Set(statisticsResult.rateStatistics.map { $0.currencyCode }),
                       supportedCurrencyCodeSet)
        
        XCTAssertEqual(statisticsResult.dataAbsentCurrencyCodeSet, nonSupportedCurrencyCodeSet)
    }
    
    func testSortByDecreasingOrderAndFilterByDiacriticInsensitiveWay() {
        // arrange
        
        let rateStatisticA: QuasiBaseResultModel.RateStatistic = QuasiBaseResultModel
            .RateStatistic(currencyCode: "code-ù",
                           localizedString: "localized-A",
                           latestExchangeRate: 1,
                           meanExchangeRate: 1,
                           fluctuation: 0)
        
        let rateStatisticB: QuasiBaseResultModel.RateStatistic = QuasiBaseResultModel
            .RateStatistic(currencyCode: "code-b",
                           localizedString: "localized-Ù",
                           latestExchangeRate: 2,
                           meanExchangeRate: 1,
                           fluctuation: -0.5)
        
        let rateStatisticC: QuasiBaseResultModel.RateStatistic = QuasiBaseResultModel
            .RateStatistic(currencyCode: "code-",
                           localizedString: "localized-",
                           latestExchangeRate: 1,
                           meanExchangeRate: 2,
                           fluctuation: 1)
        
        let rateStatisticsToBeSorted: Set<QuasiBaseResultModel.RateStatistic> = [rateStatisticA,
                                                                                 rateStatisticB,
                                                                                 rateStatisticC]
        
        let receivedSortedStatistics: [QuasiBaseResultModel.RateStatistic] = [rateStatisticA,
                                                                              rateStatisticB]
        
        // act
        let sortedRateStatistics: [QuasiBaseResultModel.RateStatistic] = QuasiBaseResultModel
            .sort(rateStatisticsToBeSorted,
                  by: .decreasing,
                  filteredIfNeededBy: "Ù")
        
        // assert
        XCTAssertEqual(sortedRateStatistics, receivedSortedStatistics)
    }
    
    func testSortByDecreasingOrderWithoutFiltering() {
        // arrange
        
        let rateStatisticA: QuasiBaseResultModel.RateStatistic = QuasiBaseResultModel
            .RateStatistic(currencyCode: "code-ù",
                           localizedString: "localized-A",
                           latestExchangeRate: 1,
                           meanExchangeRate: 1,
                           fluctuation: 0)
        
        let rateStatisticB: QuasiBaseResultModel.RateStatistic = QuasiBaseResultModel
            .RateStatistic(currencyCode: "code-b",
                           localizedString: "localized-Ù",
                           latestExchangeRate: 2,
                           meanExchangeRate: 1,
                           fluctuation: -0.5)
        
        let rateStatisticC: QuasiBaseResultModel.RateStatistic = QuasiBaseResultModel
            .RateStatistic(currencyCode: "code-",
                           localizedString: "localized-",
                           latestExchangeRate: 1,
                           meanExchangeRate: 2,
                           fluctuation: 1)
        
        let rateStatisticsToBeSorted: Set<QuasiBaseResultModel.RateStatistic> = [rateStatisticA,
                                                                                 rateStatisticB,
                                                                                 rateStatisticC]
        
        let receivedSortedStatistics: [QuasiBaseResultModel.RateStatistic] = [rateStatisticB,
                                                                              rateStatisticA,
                                                                              rateStatisticC]
        
        // act
        let sortedRateStatistics: [QuasiBaseResultModel.RateStatistic] = QuasiBaseResultModel
            .sort(rateStatisticsToBeSorted,
                  by: .increasing,
                  filteredIfNeededBy: nil)
        
        // assert
        XCTAssertEqual(sortedRateStatistics, receivedSortedStatistics)
    }
}
