import Foundation
import Combine

protocol HistoricalRateProviderProtocol {
    func historicalRatePublisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error>
}
