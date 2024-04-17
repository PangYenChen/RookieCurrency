import XCTest
import Combine
@testable import ReactiveCurrency

final class SupportedCurrencyManagerTests: XCTestCase {
    private var sut: SupportedCurrencyManager!
    
    private var supportedCurrencyProvider: TestDouble.SupportedCurrencyProvider!
    private var internalSerialDispatchQueue: DispatchQueue!
    
    private var anyCancellableSet: Set<AnyCancellable>!
    
    override func setUp() {
        supportedCurrencyProvider = TestDouble.SupportedCurrencyProvider()
        internalSerialDispatchQueue = DispatchQueue(label: "supported.currency.manager.test")
        
        sut = SupportedCurrencyManager(supportedCurrencyProvider: supportedCurrencyProvider,
                                       internalSerialDispatchQueue: internalSerialDispatchQueue)
        
        anyCancellableSet = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        anyCancellableSet.forEach { anyCancellable in anyCancellable.cancel() }
        anyCancellableSet = nil
        
        sut = nil
        
        supportedCurrencyProvider = nil
        internalSerialDispatchQueue = nil
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
        
        addTeardownBlock { [unowned self] in
            internalSerialDispatchQueue.sync { /*wait for all work items complete*/ }
        }
        
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
    
    func testFailure() throws {
        // arrange
        var receivedValue: [ResponseDataModel.CurrencyCode: String]?
        var receivedCompletion: Subscribers.Completion<Error>?
        let expectedError: URLError = URLError(URLError.Code.timedOut)
        
        // act
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedCompletion = completion },
                  receiveValue: { value in receivedValue = value })
            .store(in: &anyCancellableSet)
            
        supportedCurrencyProvider.publish(completion: .failure(expectedError))
        
        addTeardownBlock { [unowned self] in
            internalSerialDispatchQueue.sync { /*wait for all work items complete*/ }
        }
        
        // assert
        XCTAssertNil(receivedValue)
        
        do {
            let receivedCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedCompletion)
            switch receivedCompletion {
                case .finished: XCTFail("should not complete normally")
                case .failure(let failure): XCTAssertEqual(failure as? URLError, expectedError)
            }
        }
        
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        // arrange
        receivedValue = nil
        receivedCompletion = nil
        
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
        
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 2)
    }
    
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
        
        addTeardownBlock { [unowned self] in
            internalSerialDispatchQueue.sync { /*wait for all work items complete*/ }
        }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do /*assert second subscriber*/ {
            let receivedSecondValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondValue)
            XCTAssertEqual(receivedSecondValue, expectedValue)
            
            let receivedSecondCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedSecondCompletion)
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

        addTeardownBlock { [unowned self] in
            internalSerialDispatchQueue.sync { /*wait for all work items complete*/ }
        }
        
        sut.supportedCurrency()
            .sink(receiveCompletion: { completion in receivedSecondCompletion = completion },
                  receiveValue: { value in receivedSecondValue = value })
            .store(in: &anyCancellableSet)
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
        
        do /*assert second subscriber*/ {
            let receivedSecondValue: [ResponseDataModel.CurrencyCode: String] = try XCTUnwrap(receivedSecondValue)
            XCTAssertEqual(receivedSecondValue, expectedValue)
            
            let receivedSecondCompletion: Subscribers.Completion<Error> = try XCTUnwrap(receivedSecondCompletion)
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
        
        let serialQueueForAnyCancellableSet: DispatchQueue = DispatchQueue(label: "for.any.cancellable.set")
        
        // act
        let anyCancellable: AnyCancellable = sut.supportedCurrency()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { _ in })
        serialQueueForAnyCancellableSet.async { [unowned self] in anyCancellableSet.insert(anyCancellable) }
        
        concurrentDispatchQueue.async { [unowned self] in
            let callSiteCount: Int = 50
            for _ in 0..<callSiteCount {
                let anyCancellable: AnyCancellable = sut.supportedCurrency()
                    .sink(receiveCompletion: { _ in },
                          receiveValue: { _ in })
                serialQueueForAnyCancellableSet.async { [unowned self] in anyCancellableSet.insert(anyCancellable) }
            }
        }
        
        do {
            let dummySupportedSymbols: ResponseDataModel.SupportedSymbols = try TestingData
                .Instance
                .supportedSymbols()
            
            concurrentDispatchQueue.async { [unowned self] in
                supportedCurrencyProvider.publish(dummySupportedSymbols)
                
                addTeardownBlock { [unowned self] in
                    internalSerialDispatchQueue.sync { /*wait for all work items complete*/ }
                }
            }
        }
        
        concurrentDispatchQueue.async { [unowned self] in
            let callSiteCount: Int = 50
            for _ in 0..<callSiteCount {
                let anyCancellable: AnyCancellable = sut.supportedCurrency()
                    .sink(receiveCompletion: { _ in },
                          receiveValue: { _ in })
                serialQueueForAnyCancellableSet.async { [unowned self] in anyCancellableSet.insert(anyCancellable) }
            }
        }
        
        concurrentDispatchQueue.sync(flags: .barrier) { /*wait for all work items complete*/ }
        serialQueueForAnyCancellableSet.sync { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(supportedCurrencyProvider.numberOfFunctionCall, 1)
    }
    
    func testCancel() {
        // arrange
        let anyCancellable: AnyCancellable = sut.supportedCurrency()
            .sink { _ in } receiveValue: { _ in }
        
        // act
        anyCancellable.cancel()
        
        internalSerialDispatchQueue.sync { /*wait for all work items complete*/ }
        
        // assert, non-crash means passed
    }
}
