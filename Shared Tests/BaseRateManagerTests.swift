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
    
    private var historicalRateProvider: HistoricalRateProviderProtocol!
    private var latestRateProvider: LatestRateProviderProtocol!
    private var concurrentQueue: DispatchQueue!
    
    override func setUp() {
        historicalRateProvider = TestDouble.HistoricalRateProvider()
        latestRateProvider = TestDouble.LatestRateProvider()
        concurrentQueue = DispatchQueue(label: "base.rate.manager.test", attributes: .concurrent)
        
        sut = BaseRateManager(historicalRateProvider: historicalRateProvider,
                              latestRateProvider: latestRateProvider)
    }
    
    override func tearDown() {
        sut = nil
        
        historicalRateProvider = nil
        latestRateProvider = nil
        concurrentQueue = nil
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
