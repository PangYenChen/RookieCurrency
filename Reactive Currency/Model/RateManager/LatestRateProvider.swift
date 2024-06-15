import Foundation
import Combine

protocol LatestRateProviderProtocol {
    func latestRatePublisher(traceIdentifier: String) -> AnyPublisher<ResponseDataModel.LatestRate, Error>
}
