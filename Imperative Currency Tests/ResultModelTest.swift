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
        let fakeUserSettingManager: TestDouble.UserSettingManager = userSettingManager
        do /*set up fake user setting manager*/ {
            userSettingManager.numberOfDays = expectedNumberOfDays
            
            userSettingManager.baseCurrencyCode = "TWD"
            userSettingManager.resultOrder = .increasing
            userSettingManager.currencyCodeOfInterest = ["USD"]
        }
        
        let rateManagerSpy: TestDouble.RateManager = rateManager
        do /*set up rate manager spy*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            rateManagerSpy.result = dummyResult
        }
        
        // act
        fakeTimer.block?()
        
        // assert
        XCTAssertEqual(rateManagerSpy.numberOfDays, expectedNumberOfDays)
    }
}
