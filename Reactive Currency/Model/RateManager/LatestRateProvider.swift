import Foundation
import Combine

protocol LatestRateProviderProtocol {
    func latestRatePublisher(id: String) -> AnyPublisher<ResponseDataModel.LatestRate, Error>
}
