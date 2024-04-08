import Foundation
import Combine

protocol HistoricalRateProviderProtocol: BaseHistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error>
}
