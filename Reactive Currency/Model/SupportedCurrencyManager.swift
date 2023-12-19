import Foundation
import Combine

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager()
    // TODO: 這裡應該會有同時性問題，等我讀完 concurrency 之後再處理
    private var wrappedSupportedSymbols: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error>?
    
    func supportedCurrency() -> AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> {
        if let supportedCurrencyDescriptionDictionary {
            return Just(supportedCurrencyDescriptionDictionary)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        else {
            if let wrappedSupportedSymbols {
                return wrappedSupportedSymbols
            }
            else {
                let wrappedSupportedSymbols = Fetcher.shared.publisher(for: Endpoints.SupportedSymbols())
                    .map { $0.symbols }
                    .handleEvents(
                        receiveOutput: { supportedCurrencyDescriptionDictionary in
                            self.supportedCurrencyDescriptionDictionary = supportedCurrencyDescriptionDictionary
                        },
                        receiveCompletion: { _ in self.wrappedSupportedSymbols = nil },
                        receiveCancel: { self.wrappedSupportedSymbols = nil }
                    )
                    .share()
                    .eraseToAnyPublisher()
                
                self.wrappedSupportedSymbols = wrappedSupportedSymbols
                
                return wrappedSupportedSymbols
            }
        }
    }
    
    func prefetchSupportedCurrency() {
        supportedCurrency()
            .subscribe(Subscribers.Sink(receiveCompletion: { _ in }, receiveValue: { _ in }))
    }
}
