#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

import XCTest

final class ThreadSafeWrapperTests: XCTestCase {
    private var sut: ThreadSafeWrapper<IntAsDummyType>!
    
    private var dummyInitialValue: IntAsDummyType!
    
    override func setUp() {
        dummyInitialValue = 0
        
        sut = ThreadSafeWrapper<IntAsDummyType>(wrappedValue: dummyInitialValue)
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testThreadSafe() {
        // arrange
        let concurrentDispatchQueue: DispatchQueue = DispatchQueue(label: "test.thread.safe",
                                                                   attributes: .concurrent)
        let increment: Int = 50
        
        // act
        for _ in 0..<increment {
            concurrentDispatchQueue.async { [unowned self] in
                sut.writeAsynchronously { number in number + 1 }
            }
            
            concurrentDispatchQueue.async { [unowned self] in
                sut.readSynchronously { _ in /*intentionally left blank*/ }
            }
        }
        
        concurrentDispatchQueue.sync(flags: .barrier) { /*wait for all work items complete*/ }
        
        // assert
        XCTAssertEqual(sut.readSynchronously { number in number },
                       increment)
    }
}

extension ThreadSafeWrapperTests {
    typealias IntAsDummyType = Int
}
