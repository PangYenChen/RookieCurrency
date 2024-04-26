import Foundation
#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestDouble {
    class CurrencyDescriber: CurrencyDescriberProtocol {
        func localizedStringFor(currencyCode: ResponseDataModel.CurrencyCode) -> String {
            currencyCode
        }
    }
}
