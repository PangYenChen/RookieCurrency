import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

/// 這個 test case 測試 rate controller 跟 fetcher 無關的 method
/// 即時間計算的 method
final class BaseRateManagerTests: XCTestCase {
    private var sut: BaseRateManager!
    
    private var dummyHistoricalRateProvider: HistoricalRateProviderProtocol!
    private var dummyLatestRateProvider: LatestRateProviderProtocol!
    private var concurrentDispatchQueue: DispatchQueue!
    
    override func setUp() {
        dummyHistoricalRateProvider = TestDouble.HistoricalRateProvider()
        dummyLatestRateProvider = TestDouble.LatestRateProvider()
        concurrentDispatchQueue = DispatchQueue(label: "base.rate.manager.test", attributes: .concurrent)
        
        sut = BaseRateManager(historicalRateProvider: dummyHistoricalRateProvider,
                              latestRateProvider: dummyLatestRateProvider)
    }
    
    override func tearDown() {
        sut = nil
        
        dummyHistoricalRateProvider = nil
        dummyLatestRateProvider = nil
        concurrentDispatchQueue = nil
    }
    
    func testNoRetainCycleOccur() {
        // arrange
        addTeardownBlock { [weak sut] in
            // assert
            XCTAssertNil(sut)
        }
        // act
        sut = nil
    }
    
    /// 測試 RateManager.historicalRateDateStrings(numberOfDaysAgo:from:) method
    /// 模擬從執行當下的時間往前計算日期字串
    func testHistoricalRateDateStrings() throws {
        // arrange
        let startDate: Date = Date(timeIntervalSince1970: 0)
        
        // act
        let historicalDateStrings: Set<String> = sut.historicalRateDateStrings(numberOfDaysAgo: 3, from: startDate)
        
        // assert
        XCTAssertEqual(historicalDateStrings, Set(["1969-12-31", "1969-12-30", "1969-12-29"]))
    }
}
