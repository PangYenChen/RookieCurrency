import Foundation
#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

class CurrencyDescriberStub: CurrencyDescriber {
    func displayStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
        currencyCode
    }
}
