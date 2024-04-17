import Foundation
import Combine

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    override init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol,
                  locale: Locale = Locale.autoupdatingCurrent,
                  internalSerialDispatchQueue: DispatchQueue,
                  externalConcurrentDispatchQueue: DispatchQueue) {
        currentPublisher = nil
        
        super.init(supportedCurrencyProvider: supportedCurrencyProvider,
                   locale: locale,
                   internalSerialDispatchQueue: internalSerialDispatchQueue,
                   externalConcurrentDispatchQueue: externalConcurrentDispatchQueue)
    }
    
    private var currentPublisher: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error>?
    
    func supportedCurrency() -> AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> {
        internalSerialDispatchQueue.sync {
            if let cachedValue {
                return Just(cachedValue)
                    .setFailureType(to: Error.self)
                    .eraseToAnyPublisher()
            }
            else {
                if let currentPublisher {
                    return currentPublisher
                }
                else {
                    let currentPublisher: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> = supportedCurrencyProvider.supportedCurrencyPublisher()
                        .map { $0.symbols }
                        .handleEvents(
                            receiveOutput: { [unowned self] supportedCurrencyDescriptionDictionary in
                                internalSerialDispatchQueue.async {
                                    cachedValue = supportedCurrencyDescriptionDictionary
                                }
                            },
                            receiveCompletion: { [unowned self] _ in
                                internalSerialDispatchQueue.async { self.currentPublisher = nil }
                            },
                            receiveCancel: { [unowned self]  in
                                internalSerialDispatchQueue.async { self.currentPublisher = nil }
                            }
                        )
                        .share()
                        .eraseToAnyPublisher()
                    
                    self.currentPublisher = currentPublisher
                    
                    return currentPublisher
                }
            }
        }
    }
    
    func prefetchSupportedCurrency() {
        supportedCurrency()
            .subscribe(Subscribers.Sink(receiveCompletion: { _ in }, receiveValue: { _ in }))
    }
}
