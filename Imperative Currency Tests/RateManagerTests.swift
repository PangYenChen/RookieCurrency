//import XCTest
//@testable import ImperativeCurrency
//
//final class RateManagerTests: XCTestCase {
//    private var sut: RateManager!
//    
//    private var fetcher: StubFetcher!
//    private var archiver: TestDouble.Archiver!
//    private var concurrentQueue: DispatchQueue!
//    
//    override func setUp() {
//        fetcher = StubFetcher()
//        archiver = TestDouble.Archiver()
//        concurrentQueue = DispatchQueue(label: "testing queue", attributes: .concurrent)
//        
//        sut = RateManager(fetcher: fetcher,
//                          archiver: archiver,
//                          concurrentQueue: concurrentQueue)
//    }
//    
//    override func tearDown() {
//        sut = nil
//        archiver = nil
//    }
//    
//    func testNoRetainCycleOccur() {
//        // arrange
//        addTeardownBlock { [weak sut] in
//            // assert
//            XCTAssertNil(sut)
//        }
//        // act
//        sut = nil
//    }
//    
//    // TODO: `RateManager` 的 method 太長了，不好測試。等 method 拆解好之後再來寫測試。
////    func testNoCacheAndDiskData() throws {
////        // arrange
////        let stubFetcher: StubFetcher = StubFetcher()
////        let spyArchiver: TestDouble.Archiver = TestDouble.Archiver()
////        let concurrentQueue: DispatchQueue = DispatchQueue(label: "testing queue", attributes: .concurrent)
////        
////        sut = RateManager(fetcher: stubFetcher,
////                          archiver: spyArchiver,
////                          concurrentQueue: concurrentQueue)
////        
////        var receivedResult: Result<BaseRateManager.RateTuple,
////                                   Error>?
////        let dummyStartingDate: Date = Date(timeIntervalSince1970: 0)
////        let numberOfDays: Int = 3
////        
////        // act
////        sut.getRateFor(numberOfDays: numberOfDays,
////                       from: dummyStartingDate,
////                       completionHandlerQueue: concurrentQueue) { result in receivedResult = result }
////        
////        concurrentQueue.sync(flags: .barrier) { } // 卡一個空的 work item，等 sut 執行完 completion handler 再繼續
////        
////        // assert
////        do {
////            let receivedResult: Result<BaseRateManager.RateTuple, any Error> = try XCTUnwrap(receivedResult)
////            
////            switch receivedResult {
////                case .success(let (_, historicalRateSet)):
////                    XCTAssertEqual(historicalRateSet.count, numberOfDays)
////                case .failure(let failure):
////                    XCTFail("should not receive any failure but receive: \(failure)")
////            }
////        }
////        
////        do {
////            XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
////            XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
////            XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
////            XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
////        }
////    }
//    
////    func testAllFromCache() {
////        // arrange
////        let stubFetcher = StubFetcher()
////        let spyArchiver = TestDouble.SpyArchiver.self
////        sut = RateManager(fetcher: stubFetcher, archiver: spyArchiver)
////        
////        let expectation = expectation(description: "should receive rate")
////        let dummyStartingDate = Date(timeIntervalSince1970: 0)
////        let numberOfDays = 3
////        
////        sut.getRateFor(numberOfDays: numberOfDays,
////                       from: dummyStartingDate) { [unowned self] result in
////            switch result {
////            case .success(let (_ , historicalRateSet)):
////                // first assert which may be not necessary
////                XCTAssertEqual(historicalRateSet.count, numberOfDays)
////                XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
////                XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
////                XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 1)
////                XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
////                // act
////                sut.getRateFor(numberOfDays: numberOfDays,
////                               from: dummyStartingDate) { result in
////                    switch result {
////                    case .success(let (_ , historicalRateSet)):
////                        // assert
////                        XCTAssertEqual(historicalRateSet.count, numberOfDays)
////                        XCTAssertEqual(spyArchiver.numberOfArchiveCall, numberOfDays)
////                        XCTAssertEqual(spyArchiver.numberOfUnarchiveCall, 0)
////                        XCTAssertEqual(stubFetcher.numberOfLatestEndpointCall, 2)
////                        XCTAssertEqual(stubFetcher.dateStringOfHistoricalEndpointCall.count, numberOfDays)
////                        expectation.fulfill()
////                    case .failure(let failure):
////                        XCTFail("should not receive any failure but receive: \(failure)")
////                    }
////                }
////            case .failure(let failure):
////                XCTFail("should not receive any failure but receive: \(failure)")
////            }
////        }
////        
////        waitForExpectations(timeout: timeoutInterval)
////    }
//}
