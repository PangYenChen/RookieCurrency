import XCTest
@testable import ImperativeCurrency

final class RateManagerTests: XCTestCase {
    private var sut: RateManager!
    
    private var historicalRateProvider: TestDouble.HistoricalRateProvider!
    private var latestRateProvider: TestDouble.LatestRateProvider!
    
    private let timeoutInterval: TimeInterval = 1
    
    override func setUp() {
        historicalRateProvider = TestDouble.HistoricalRateProvider()
        latestRateProvider = TestDouble.LatestRateProvider()
        
        sut = RateManager(historicalRateProvider: historicalRateProvider,
                          latestRateProvider: latestRateProvider)
    }
    
    override func tearDown() {
        sut = nil
        
        historicalRateProvider = nil
        latestRateProvider = nil
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
        let historicalRateDateStrings: Set<String> = sut.historicalRateDateStrings(numberOfDaysAgo: numberOfDays,
                                                                                   from: startDate)
        let expectation: XCTestExpectation = expectation(description: "dispatch group notifies")
        let dummyDispatchQueue: DispatchQueue = DispatchQueue(label: "rate.manager.tests")
        
        // act
        sut.getRateFor(numberOfDays: numberOfDays,
                       from: startDate,
                       completionHandlerQueue: dummyDispatchQueue) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        do /*simulate historical rate provider's result*/ {
            try historicalRateDateStrings
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
        
        waitForExpectations(timeout: timeoutInterval)
        
        // assert
        do {
            let receivedResult: Result<BaseRateManager.RateTuple, any Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success(let (_, historicalRateSet)):
                    XCTAssertEqual(Set(historicalRateSet.map { historicalRate in historicalRate.dateString }),
                                   historicalRateDateStrings)
                case .failure(let failure):
                    XCTFail("should not receive any failure but receive: \(failure)")
            }
        }
    }
    
    func testHistoricalRateFailure() throws {
        // arrange
        let fakeHistoricalRateProvider: TestDouble.HistoricalRateProvider = historicalRateProvider
        let fakeLatestRateProvider: TestDouble.LatestRateProvider = latestRateProvider
        
        var receivedResult: Result<BaseRateManager.RateTuple, Error>?
        let expectedTimeOutError: URLError = URLError(URLError.Code.timedOut)
        
        let startDate: Date = Date(timeIntervalSince1970: 0)
        let numberOfDays: Int = 3
        let historicalRateDateStrings: Set<String> = sut.historicalRateDateStrings(numberOfDaysAgo: numberOfDays,
                                                                                   from: startDate)
        let expectation: XCTestExpectation = expectation(description: "dispatch group notifies")
        let dummyDispatchQueue: DispatchQueue = DispatchQueue(label: "rate.manager.tests")
        
        // act
        sut.getRateFor(numberOfDays: numberOfDays,
                       from: startDate,
                       completionHandlerQueue: dummyDispatchQueue) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        do /*simulate historical rate provider's result*/ {
            historicalRateDateStrings
                .forEach { historicalRateDateString in
                    fakeHistoricalRateProvider
                        .executeHistoricalRateResultHandlerFor(dateString: historicalRateDateString,
                                                               with: .failure(expectedTimeOutError))
                }
        }
        
        do /*simulate latest rate provider's result*/ {
            let dummyLatestRate: ResponseDataModel.LatestRate = try TestingData.Instance.latestRate()
            fakeLatestRateProvider.executeLatestRateResultHandler(with: .success(dummyLatestRate))
        }
        
        waitForExpectations(timeout: timeoutInterval)
        
        // assert
        do {
            let receivedResult: Result<BaseRateManager.RateTuple, any Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success(let rateTuple):
                    XCTFail("should not receive a rate tuple but receive: \(rateTuple)")
                case .failure(let failure):
                    let receivedFailure: URLError = try XCTUnwrap(failure as? URLError)
                    XCTAssertEqual(receivedFailure, expectedTimeOutError)
            }
        }
    }
    
    func testLatestRateFailure() throws {
        // arrange
        let fakeHistoricalRateProvider: TestDouble.HistoricalRateProvider = historicalRateProvider
        let fakeLatestRateProvider: TestDouble.LatestRateProvider = latestRateProvider
        
        var receivedResult: Result<BaseRateManager.RateTuple, Error>?
        let expectedTimeOutError: URLError = URLError(URLError.Code.timedOut)
        
        let startDate: Date = Date(timeIntervalSince1970: 0)
        let numberOfDays: Int = 3
        let historicalRateDateStrings: Set<String> = sut.historicalRateDateStrings(numberOfDaysAgo: numberOfDays,
                                                                                   from: startDate)
        let expectation: XCTestExpectation = expectation(description: "dispatch group notifies")
        let dummyDispatchQueue: DispatchQueue = DispatchQueue(label: "rate.manager.tests")
        
        // act
        sut.getRateFor(numberOfDays: numberOfDays,
                       from: startDate,
                       completionHandlerQueue: dummyDispatchQueue) { result in
            receivedResult = result
            expectation.fulfill()
        }
        
        do /*simulate historical rate provider's result*/ {
            try historicalRateDateStrings
                .forEach { historicalRateDateString in
                    let dummyHistoricalRate: ResponseDataModel.HistoricalRate = try TestingData.Instance.historicalRateFor(dateString: historicalRateDateString)
                    fakeHistoricalRateProvider
                        .executeHistoricalRateResultHandlerFor(dateString: historicalRateDateString,
                                                               with: .success(dummyHistoricalRate))
                }
        }
        
        do /*simulate latest rate provider's result*/ {
            fakeLatestRateProvider.executeLatestRateResultHandler(with: .failure(expectedTimeOutError))
        }
        
        waitForExpectations(timeout: timeoutInterval)
        
        // assert
        do {
            let receivedResult: Result<BaseRateManager.RateTuple, Error> = try XCTUnwrap(receivedResult)
            
            switch receivedResult {
                case .success(let rateTuple):
                    XCTFail("should not receive a rate tuple but receive: \(rateTuple)")
                case .failure(let failure):
                    let receivedFailure: URLError = try XCTUnwrap(failure as? URLError)
                    XCTAssertEqual(receivedFailure, expectedTimeOutError)
            }
        }
    }
}
