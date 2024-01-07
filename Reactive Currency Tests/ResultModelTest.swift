import XCTest
import Combine
@testable import ReactiveCurrency

class ResultModelTest: XCTestCase {
    func testPassNumberOfDaysToRateManager() throws {
        // arrange
        let currencyDescriberStub: CurrencyDescriberProtocol = TestDouble.CurrencyDescriber()
        
        let userSettingManagerStub: UserSettingManagerProtocol
        let numberOfDays = Int.random(in: 1...10)
        do {
            let dummyBaseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
            let dummyResultOrder: BaseResultModel.Order = .increasing
            let dummyCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD"]
            userSettingManagerStub = TestDouble.UserSettingManager(
                numberOfDays: numberOfDays,
                baseCurrencyCode: dummyBaseCurrencyCode,
                resultOrder: dummyResultOrder,
                currencyCodeOfInterest: dummyCurrencyCodeOfInterest
            )
        }
        
        let rateManagerSpy: TestDouble.RateManager
        do {
            let dummyLatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            rateManagerSpy = TestDouble.RateManager(result: dummyResult)
        }
        
        // act
        let sut: ResultModel = ResultModel(currencyDescriber: currencyDescriberStub,
                                           rateManager: rateManagerSpy,
                                           userSettingManager: userSettingManagerStub)
        sut.state
            .subscribe(AnySubscriber())
        
        // assert
        XCTAssertEqual(numberOfDays, rateManagerSpy.numberOfDays)
    }
}
