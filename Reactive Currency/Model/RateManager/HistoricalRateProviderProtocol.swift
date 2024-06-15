import Foundation
import Combine

protocol HistoricalRateProviderProtocol: BaseHistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String, traceIdentifier: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error>
}
