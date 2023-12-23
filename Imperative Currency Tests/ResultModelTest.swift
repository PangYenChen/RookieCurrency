import XCTest
@testable import ImperativeCurrency

final class ResultModelTest: XCTestCase {
    func testPassNumberOfDaysToRateManager() throws {
        // arrange
        let currencyDescriberStub: CurrencyDescriberStub = CurrencyDescriberStub()
        
        let userSettingManagerStub: UserSettingManagerStub
        let numberOfDays = Int.random(in: 1...10)
        do {
            let dummyBaseCurrencyCode: ResponseDataModel.CurrencyCode = "TWD"
            let dummyResultOrder: BaseResultModel.Order = .increasing
            let dummyCurrencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD"]
            userSettingManagerStub = UserSettingManagerStub(
                numberOfDays: numberOfDays,
                baseCurrencyCode: dummyBaseCurrencyCode,
                resultOrder: dummyResultOrder,
                currencyCodeOfInterest: dummyCurrencyCodeOfInterest
            )
        }
        
        let rateManagerSpy: RateManagerSpy
        do {
            let dummyLatestRate = try TestingData.Instance.latestRate()
            let dummyHistoricalRate = try TestingData.Instance.historicalRateFor(dateString: "1970-01-01")
            let dummyResult: Result<(latestRate: ResponseDataModel.LatestRate, historicalRateSet: Set<ResponseDataModel.HistoricalRate>), Error> = .success((latestRate: dummyLatestRate, historicalRateSet: [dummyHistoricalRate]))
            rateManagerSpy = RateManagerSpy(result: dummyResult)
        }
        
        // act
        let sut: ResultModel = ResultModel(currencyDescriber: currencyDescriberStub,
                                           rateManager: rateManagerSpy,
                                           userSettingManager: userSettingManagerStub)
        
        // assert
        XCTAssertEqual(numberOfDays, rateManagerSpy.numberOfDays)
    }
}
