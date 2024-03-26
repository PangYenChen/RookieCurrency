import XCTest
@testable import ImperativeCurrency

final class ImperativeRateManagerTests: XCTestCase {
    var sut: RateManager!
    
    override func tearDown() {
        sut = nil
        TestDouble.SpyArchiver.reset()
    }
    
    // TODO: `RateManager` 的 method 太長了，不好測試。等 method 拆解好之後再來寫測試。
//    func testNoCacheAndDiskData() throws {
//        // arrange
//        let stubFetcher: StubFetcher = StubFetcher()
//        let spyArchiver: TestDouble.SpyArchiver.Type = TestDouble.SpyArchiver.self
//        let concurrentQueue = DispatchQueue(label: "testing queue", attributes: .concurrent)
//        
//        sut = RateManager(fetcher: stubFetcher,
//                          archiver: spyArchiver,
//                          concurrentQueue: concurrentQueue)
//        
//        var receivedResult: Result<BaseRateManager.RateTuple,
//                                   Error>?
//        let dummyStartingDate = Date(timeIntervalSince1970: 0)
//        let numberOfDays = 3
//        
//        // act
//        sut.getRateFor(numberOfDays: numberOfDays,
//                       from: dummyStartingDate,
//                       completionHandlerQueue: concurrentQueue) { result in receivedResult = result }
//        
//        concurrentQueue.sync(flags: .barrier) { } // 卡一個空的 work item，等 sut 執行完 completion handler 在繼續
//        
//        // assert
//        do {
//            let receivedResult = try XCTUnwrap(receivedResult)
//            
//            switch receivedResult {
//            case .success(let (_, historicalRateSet)):
//                XCTAssertEqual(historicalRateSet.count, numberOfDays)
//            case .failure(let failure):
//                XCTFail("should not receive any failure but receive: \(failure)")
//            }
//        }
//        
//        do {
//            XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
//            XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
//            XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
//            XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
//        }
//    }
//    
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

final class StubFetcher: FetcherProtocol { // TODO: 放進 test double 的 name space
    
    private(set) var numberOfLatestEndpointCall = 0
    
    private(set) var dateStringOfHistoricalEndpointCall: Set<String> = []
    
    func fetch<Endpoint>(_ endpoint: Endpoint,
                         completionHandler: @escaping (Result<Endpoint.ResponseType, Error>) -> Void)
    where Endpoint: ImperativeCurrency.EndpointProtocol {
        if endpoint.url.path.contains("latest") {
            do {
                let latestRate = try XCTUnwrap(TestingData.Instance.latestRate() as? Endpoint.ResponseType)
                numberOfLatestEndpointCall += 1
                
                completionHandler(.success(latestRate))
            }
            catch {
                completionHandler(.failure(error))
            }
        }
        else {
            let dateString = endpoint.url.lastPathComponent
            do {
                if AppUtility.requestDateFormatter.date(from: dateString) != nil,
                   let historicalRate = try TestingData.Instance.historicalRateFor(dateString: dateString) as? Endpoint.ResponseType {
                    
                    dateStringOfHistoricalEndpointCall.insert(dateString)
                    
                    completionHandler(.success(historicalRate))
                }
                else {
                    completionHandler(.failure(Fetcher.Error.unknownError))
                }
            }
            catch {
                completionHandler(.failure(error))
                
            }
        }
    }
}
