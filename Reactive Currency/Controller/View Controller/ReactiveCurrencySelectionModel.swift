import Foundation
import Combine
    // TODO: protocol 名字要想一下
protocol ReactiveCurrencySelectionModel: CurrencySelectionModelProtocol {
    var result: AnyPublisher<Result<[ResponseDataModel.CurrencyCode], Error>, Never> { get }
}
