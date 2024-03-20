import XCTest
import Combine
@testable import ReactiveCurrency

class ResultModelTest: XCTestCase {
    func testNoRetainCycleOccur() {
        // arrange
        var sut: ResultModel?
        do /*set up sut*/ {
            let dummyUserSettingManager: UserSettingManagerProtocol = TestDouble.UserSettingManager()
            let dummyRateManager: RateManagerProtocol = TestDouble.RateManager()
            let dummyCurrencyCodeDescriber: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
            let dummyTimer: TimerProtocol = TestDouble.Timer()
            
            sut = ResultModel(userSettingManager: dummyUserSettingManager,
                              rateManager: dummyRateManager,
                              currencyDescriber: dummyCurrencyCodeDescriber,
                              timer: dummyTimer)
        }
        
        addTeardownBlock { [weak sut] in
            // assert
            XCTAssertNil(sut)
        }
        
        // act
        sut = nil
    }
    
    func testPassNumberOfDaysToRateManager() throws {
        // arrange
        let rateManagerSpy: TestDouble.RateManager
        let fakeTimer: TestDouble.Timer = TestDouble.Timer()
        let sut: ResultModel
        let expectedNumberOfDays: Int = Int.random(in: 1...10)
        do /*set up sut*/ {
            let userSettingManagerStub: TestDouble.UserSettingManager = TestDouble.UserSettingManager()
            userSettingManagerStub.numberOfDays = expectedNumberOfDays
            
            rateManagerSpy = TestDouble.RateManager()
            do /*set up rate manager spy*/ {
                let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
                let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
                let dummyResult: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
                rateManagerSpy.result = dummyResult
            }
            
            let dummyCurrencyCodeDescriber: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
            
            sut = ResultModel(userSettingManager: userSettingManagerStub,
                              rateManager: rateManagerSpy,
                              currencyDescriber: dummyCurrencyCodeDescriber,
                              timer: fakeTimer)
        }
        
        // act
        sut.rateStatistics
            .subscribe(AnySubscriber())
        
        fakeTimer.publish()
        
        // assert
        XCTAssertEqual(expectedNumberOfDays, rateManagerSpy.numberOfDays)
    }
}
