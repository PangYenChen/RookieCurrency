#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

import Foundation

extension Endpoints {
    struct TestEndpoint: EndpointProtocol {
        typealias ResponseType = ResponseDataModel.TestDataModel
        
        let url: URL
    }
}
