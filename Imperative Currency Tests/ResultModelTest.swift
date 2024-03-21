import XCTest
@testable import ImperativeCurrency

final class ResultModelTest: XCTestCase {
    // MARK: - system under test
    private var sut: ResultModel!
    
    // MARK: - test double
    private var userSettingManager: TestDouble.UserSettingManager!
    private var rateManager: TestDouble.RateManager!
    private var dummyCurrencyCodeDescriber: CurrencyDescriberProtocol!
    private var fakeTimer: TestDouble.Timer!
    
    override func setUp() {
        userSettingManager = TestDouble.UserSettingManager()
        rateManager = TestDouble.RateManager()
        dummyCurrencyCodeDescriber = TestDouble.CurrencyDescriber()
        fakeTimer = TestDouble.Timer()
        
        sut = ResultModel(userSettingManager: userSettingManager,
                          rateManager: rateManager,
                          currencyDescriber: dummyCurrencyCodeDescriber,
                          timer: fakeTimer)
    }
    
    override func tearDown() {
        sut = nil
        
        fakeTimer = nil
        dummyCurrencyCodeDescriber = nil
        rateManager = nil
        userSettingManager = nil
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
    
    func testPassNumberOfDaysToRateManager() throws {
        // arrange
        let expectedNumberOfDays: Int = Int.random(in: 1...10)
        let userSettingManagerStub: TestDouble.UserSettingManager = userSettingManager
        userSettingManagerStub.numberOfDays = expectedNumberOfDays
        
        let rateManagerSpy: TestDouble.RateManager = rateManager
        
        // act
        fakeTimer.block?()
        do /*fake the rate manager result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<BaseRateManager.RateTuple, Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            
            rateManagerSpy.executeCompletionHandlerWith(result: dummyResult)
        }
        
        // assert
        XCTAssertEqual(rateManagerSpy.numberOfDays, expectedNumberOfDays)
    }
    
    
//    func testAllSucceed() throws {
//        // arrange
//        var expectedRateStatics: [ResultModel.RateStatistic]?
//        
//        sut.rateStatisticsHandler = { rateStatics in
//            expectedRateStatics = rateStatics
//        }
//        
//        // act
//        fakeTimer.block?()
//        do /*set up rate manager stub*/ {
//            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
//            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
//            let dummyResult: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
//            rateManager.result = dummyResult
//        }
//        
//        // assert
//        do {
//            let expectedRateStatics: [ResultModel.RateStatistic] = try XCTUnwrap(expectedRateStatics)
//        }
//        
//    }
}
