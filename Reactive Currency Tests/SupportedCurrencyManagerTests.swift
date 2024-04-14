import XCTest
import Combine
@testable import ReactiveCurrency

final class SupportedCurrencyManagerTests: XCTestCase {
    private var sut: SupportedCurrencyManager!
    
    private var supportedCurrencyProvider: TestDouble.SupportedCurrencyProvider!
    private var serialDispatchQueue: DispatchQueue!
    
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        supportedCurrencyProvider = TestDouble.SupportedCurrencyProvider()
        serialDispatchQueue = DispatchQueue(label: "supported.currency.manager.test")
        
        sut = SupportedCurrencyManager(supportedCurrencyProvider: supportedCurrencyProvider,
                                       serialDispatchQueue: serialDispatchQueue)
        
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        sut = nil
        
        supportedCurrencyProvider = nil
        serialDispatchQueue = nil
    }
    
    func testSuccess() throws {
        // arrange
        var receivedValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedCompletion: Subscribers.Completion<Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { value in receivedValue = value })
            .store(in: &anyCancellableSet)
        
        supportedCurrencyProvider.publish(supportedSymbols)
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        do /*assert about receivedValue*/ {
            let receivedValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedValue)
            XCTAssertEqual(receivedValue, expectedValue)
        }
        
        do /*assert about receivedCompletion*/ {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
    
//    func testFailure() throws {
//        // arrange
//        var receivedValue: [ResponseDataModel.CurrencyCode: String]?
//        var receivedCompletion: Subscribers.Completion<Error>?
//        let expectedError: URLError = URLError(URLError.Code.timedOut)
//        
//        // act
//        sut.supportedCurrency()
//            .sink(receiveCompletion: { completion in receivedCompletion = completion },
//                  receiveValue: { value in receivedValue = value })
//            .store(in: &anyCancellableSet)
//            
//        supportedCurrencyProvider.publish(completion: .failure(expectedError))
//        
//        serialDispatchQueue.sync { /*wait for all work items complete*/ }
//        
//        // assert
//        
//        XCTAssertNil(receivedValue)
//        do {
//            let receivedCompletion = try XCTUnwrap(receivedCompletion)
//            switch receivedCompletion {
//                case .finished: XCTFail("should not complete normally")
//                case .failure(let failure): XCTAssertEqual(failure as? URLError, expectedError)
//            }
//        }
//        
//        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
//        
//        // arrange
//        receivedValue = nil
//        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
//            .Instance
//            .supportedSymbols()
//        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
//        
//        // act
//        sut.supportedCurrency()
//            .sink(receiveCompletion: { completion in receivedCompletion = completion },
//                  receiveValue: { value in receivedValue = value })
//            .store(in: &anyCancellableSet)
//        
//        supportedCurrencyProvider.publish(completion: .success(expectedValue))
//        
//        serialDispatchQueue.sync { /*wait for all work items complete*/ }
//        
//        // assert
//        do {
//            let receivedResult: Result<[ResponseDataModel.CurrencyCode: String], any Error> = try XCTUnwrap(receivedResult)
//            switch receivedResult {
//                case .success(let supportedCurrency): XCTAssertEqual(supportedCurrency, expectedValue)
//                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
//            }
//        }
//        
//        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 2)
//    }
    
    func testSecondCallBeforeFirstReturn() throws {
        // arrange
        var receivedSecondValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedSecondCompletion: Subscribers.Completion<Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.prefetchSupportedCurrency()
        
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedSecondCompletion = completion },
                  receiveValue: { value in receivedSecondValue = value })
            .store(in: &anyCancellableSet)
        
        supportedCurrencyProvider.publish(supportedSymbols)
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do /*assert second subscriber*/ {
            let receivedSecondValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondValue)
            XCTAssertEqual(receivedSecondValue, expectedValue)
            
            var receivedSecondCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedSecondCompletion)
            switch receivedSecondCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
    
    func testTwoCallSiteSequentially() throws {
        // arrange
        var receivedSecondValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedSecondCompletion: Subscribers.Completion<Error>?
        
        let supportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
            .Instance
            .supportedSymbols()
        let expectedValue: [ResponseDataModel.CurrencyCode: String] = supportedSymbols.symbols
        
        // act
        sut.prefetchSupportedCurrency()
        
        supportedCurrencyProvider.publish(supportedSymbols)
        
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedSecondCompletion = completion },
                  receiveValue: { value in receivedSecondValue = value })
            .store(in: &anyCancellableSet)
        
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do /*assert second subscriber*/ {
            let receivedSecondValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondValue)
            XCTAssertEqual(receivedSecondValue, expectedValue)
            
            var receivedSecondCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedSecondCompletion)
            switch receivedSecondCompletion {
                case .finished: break
                case .failure(let failure): XCTFail("should not receive failure, but receive: \(failure)")
            }
        }
    }
    
    func testManyCallSiteSimultaneously() throws {
        // arrange
        let concurrentDispatchQueue: DispatchQueue = DispatchQueue(label: "test.many.call.site.simultaneously",
                                                                   attributes: .concurrent)
        
        // act
        concurrentDispatchQueue.async { [unowned self] in
            let callSiteCount: Int = 50
            for _ in 0..<50 {
                sut.supportedCurrency()
                    .sink(receiveCompletion: { _ in },
                          receiveValue: { _ in })
                    .store(in: &anyCancellableSet)
            }
        }
        
        do {
            let dummySupportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
                .Instance
                .supportedSymbols()
            
            concurrentDispatchQueue.async { [unowned self] in
                supportedCurrencyProvider.publish(dummySupportedSymbols)
            }
        }
        
        concurrentDispatchQueue.sync(flags: .barrier) { /*wait for all work items complete*/ }
        serialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert, non-crash means passed
    }
}
