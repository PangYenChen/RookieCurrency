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
    
    func testRunOutOfKeysConcurrently() throws {
        // arrange
        let concurrentQueue: DispatchQueue = DispatchQueue(label: "test.run.out.of.keys.concurrently", attributes: .concurrent)
        
        for _ in 0..<(unusedAPIKeys.count - 1) {
            concurrentQueue.async { [unowned self] in
                switch sut.getUsingAPIKey() {
                    case .success(let usingAPIKey):
                        switch sut.getUsingAPIKeyAfterDeprecating(usingAPIKey) {
                            case .success: break
                            case .failure: XCTFail("api key的數量應該夠多，即使拿到的對象不對，至少能拿到東西")
                        }
                        
                    case .failure:
                        XCTFail("api key的數量應該夠多，即使拿到的對象不對，至少能拿到東西")
                }
            }
        }
        
        concurrentQueue.sync(flags: .barrier) { /*intentionally left blank*/ }
    }
}
