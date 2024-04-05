import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

final class KeyManagerTests: XCTestCase {
    private var sut: KeyManager!
    
    private var concurrentQueue: DispatchQueue!
    private var unusedAPIKeys: Set<String>!

    override func setUp() {
        concurrentQueue = DispatchQueue(label: "key.manager.tests", attributes: .concurrent)
        unusedAPIKeys = Set((0..<100).map { _ in UUID().uuidString })
        
        sut = KeyManager(concurrentQueue: concurrentQueue,
                         unusedAPIKeys: unusedAPIKeys)
    }

    override func tearDown() {
        sut = nil
        
        unusedAPIKeys = nil
        concurrentQueue = nil
    }
    
    func testRunOutOfKeys() throws {
        // arrange, do nothing
        
        // act, do nothing
        
        // assert
        var usingAPIKey: String = try XCTUnwrap(sut.getUsingAPIKey().get())
        
        for _ in 0..<(unusedAPIKeys.count - 1) {
            usingAPIKey = try sut.getUsingAPIKeyAfterDeprecating(usingAPIKey).get()
        }
        
        XCTAssertNil(try? sut.getUsingAPIKeyAfterDeprecating(usingAPIKey).get())
    }
}
