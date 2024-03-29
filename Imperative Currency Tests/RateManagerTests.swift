import XCTest
@testable import ImperativeCurrency

final class RateManagerTests: XCTestCase {
    private var sut: RateManager!
    
    private var historicalRateProvider: TestDouble.HistoricalRateProvider!
    private var latestRateProvider: TestDouble.LatestRateProvider!
    private var concurrentQueue: DispatchQueue!
    
    override func setUp() {
        historicalRateProvider = TestDouble.HistoricalRateProvider()
        latestRateProvider = TestDouble.LatestRateProvider()
        concurrentQueue = DispatchQueue(label: "base.rate.manager.test", attributes: .concurrent)
        
        sut = RateManager(historicalRateProvider: historicalRateProvider,
                          latestRateProvider: latestRateProvider,
                          concurrentQueue: concurrentQueue)
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
    
    func testAllSuccess() throws {
        // arrange
        let fakeHistoricalRateProvider: TestDouble.HistoricalRateProvider = historicalRateProvider
        let fakeLatestRateProvider: TestDouble.LatestRateProvider = latestRateProvider
        
        var receivedResult: Result<BaseRateManager.RateTuple, Error>?
        let startDate: Date = Date(timeIntervalSince1970: 0)
        let numberOfDays: Int = 3
        let expectedHistoricalRateDateStrings: Set<String> = sut
            .historicalRateDateStrings(numberOfDaysAgo: numberOfDays,
                                       from: startDate)
        
        // act
        sut.getRateFor(numberOfDays: numberOfDays,
                       from: startDate,
                       completionHandlerQueue: concurrentQueue) { result in receivedResult = result }
        
        do /*simulate historical rate provider's result*/ {
            try expectedHistoricalRateDateStrings
                .forEach { historicalRateDateString in
                    let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: historicalRateDateString)
                    fakeHistoricalRateProvider
                        .executeHistoricalRateResultHandlerFor(dateString: historicalRateDateString,
                                                               with: .success(dummyHistoricalRate))
                }
        }
        
        do /*simulate latest rate provider's result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            fakeLatestRateProvider.executeLatestRateResultHandler(with: .success(dummyLatestRate))
        }
        
        concurrentQueue.sync(flags: .barrier) { } // 卡一個空的 work item，等 sut 執行完 completion handler 再繼續
        
        // assert
        do {
            let receivedResult: Result<BaseRateManager.RateTuple, any Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success(let (_, historicalRateSet)):
                    XCTAssertEqual(Set(historicalRateSet.map { historicalRate in historicalRate.dateString }),
                                   expectedHistoricalRateDateStrings)
                case .failure(let failure):
                    XCTFail("should not receive any failure but receive: \(failure)")
            }
        }
    }
    
//    func testAllFromCache() {
//        // arrange
//        let stubFetcher = StubFetcher()
//        let spyArchiver = TestDouble.SpyArchiver.self
//        sut = RateManager(fetcher: stubFetcher, archiver: spyArchiver)
//        
//        let expectation = expectation(description: "should receive rate")
//        let dummyStartingDate = Date(timeIntervalSince1970: 0)
//        let numberOfDays = 3
//        
//        sut.getRateFor(numberOfDays: numberOfDays,
//                       from: dummyStartingDate) { [unowned self] result in
//            switch result {
//            case .success(let (_ , historicalRateSet)):
//                // first assert which may be not necessary
//                XCTAssertEqual(historicalRateSet.count, numberOfDays)
//                XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
//                XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
//                XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
//                XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
//                // act
//                sut.getRateFor(numberOfDays: numberOfDays,
//                               from: dummyStartingDate) { result in
//                    switch result {
//                    case .success(let (_ , historicalRateSet)):
//                        // assert
//                        XCTAssertEqual(historicalRateSet.count, numberOfDays)
//                        XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
//                        XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
//                        XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 2)
//                        XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
//                        expectation.fulfill()
//                    case .failure(let failure):
//                        XCTFail("should not receive any failure but receive: \(failure)")
//                    }
//                }
//            case .failure(let failure):
//                XCTFail("should not receive any failure but receive: \(failure)")
//            }
//        }
//        
//        waitForExpectations(timeout: timeoutInterval)
//    }
}
