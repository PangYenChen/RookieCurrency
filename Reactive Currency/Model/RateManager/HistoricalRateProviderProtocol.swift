import Foundation
import Combine

protocol HistoricalRateProviderProtocol: BaseHistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String, id: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error>
}
