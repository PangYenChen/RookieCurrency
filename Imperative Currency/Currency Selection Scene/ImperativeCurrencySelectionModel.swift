import Foundation

protocol ImperativeCurrencySelectionModelProtocol: CurrencySelectionModelProtocol {
    var stateHandler: ((Result<[ResponseDataModel.CurrencyCode], Error>) -> Void)? { get set }
}
