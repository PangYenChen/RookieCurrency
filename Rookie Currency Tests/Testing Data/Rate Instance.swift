import Foundation
import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#elseif REACTIVE_CURRENCY_TESTS
@testable import ReactiveCurrency
#else
@testable import ReactiveCurrency // dead code
#endif

extension TestingData {
    enum Instance {
        static func historicalRateFor(dateString: String) throws -> ResponseDataModel.HistoricalRate {
            let historicalRateData: Data = try XCTUnwrap(TestingData.historicalRateDataFor(dateString: dateString))
            return try ResponseDataModel.jsonDecoder.decode(ResponseDataModel.HistoricalRate.self, from: historicalRateData)
        }
        
        static func latestRate() throws -> ResponseDataModel.LatestRate {
            try ResponseDataModel.jsonDecoder.decode(ResponseDataModel.LatestRate.self, from: TestingData.latestData())
        }
        
        static func supportedSymbols() throws -> ResponseDataModel.SupportedSymbols {
            try ResponseDataModel
                .jsonDecoder
                .decode(ResponseDataModel.SupportedSymbols.self,
                        from: XCTUnwrap(TestingData.supportedSymbols))
        }
    }
}
