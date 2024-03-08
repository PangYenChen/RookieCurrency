import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

final class UserSettingManagerTests: XCTestCase {
    private var sut: UserSettingManager!
    
    private var userDefaultsSpy: TestDouble.UserDefaults!
    
//    func test<#Name#>() {
//        <#statements#>
//    }
}
