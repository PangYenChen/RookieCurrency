import Foundation
#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestDouble {
    class UserSettingManager: UserSettingManagerProtocol {
        var numberOfDays: Int
        
        var baseCurrencyCode: ResponseDataModel.CurrencyCode
        
        var resultOrder: BaseResultModel.Order
        
        var currencyCodeOfInterest: Set<ResponseDataModel.CurrencyCode>
        
        init() {
            numberOfDays = 3
            baseCurrencyCode = "TWD"
            resultOrder = .decreasing
            currencyCodeOfInterest = ["USD", "JPY"]
        }
    }
}
