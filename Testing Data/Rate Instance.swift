import Foundation
import XCTest

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif

extension TestingData {
    
    enum Instance {
        static func historicalRateFor(dateString: String) throws -> ResponseDataModel.HistoricalRate {
            let historicalRateData = try XCTUnwrap(TestingData.historicalRateDataFor(dateString: dateString))
            return try ResponseDataModel.jsonDecoder.decode(ResponseDataModel.HistoricalRate.self, from: historicalRateData)
        }
        
        static func latestRate() throws -> ResponseDataModel.LatestRate {
            let latestRateData = try XCTUnwrap(TestingData.latestData)
            return try ResponseDataModel.jsonDecoder.decode(ResponseDataModel.LatestRate.self, from: latestRateData)
        }
    }
}
