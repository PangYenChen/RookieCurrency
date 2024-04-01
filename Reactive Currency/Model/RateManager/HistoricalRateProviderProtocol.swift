import Foundation
import Combine

protocol HistoricalRateProviderProtocol: BaseHistoricalRateProviderProtocol {
    func publisherFor(dateString: String) -> AnyPublisher<ResponseDataModel.HistoricalRate, Error>
}
