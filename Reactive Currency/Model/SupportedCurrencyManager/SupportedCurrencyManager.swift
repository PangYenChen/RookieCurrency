import Foundation
import Combine

class SupportedCurrencyManager: BaseSupportedCurrencyManager {
    override init(supportedCurrencyProvider: SupportedCurrencyProviderProtocol,
                  locale: Locale = Locale.autoupdatingCurrent,
                  internalSerialDispatchQueue: DispatchQueue) {
        currentPublisher = nil
        
        super.init(supportedCurrencyProvider: supportedCurrencyProvider,
                   locale: locale,
                   internalSerialDispatchQueue: internalSerialDispatchQueue)
    }
    
    private var currentPublisher: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error>?
    
    func supportedCurrencyPublisher() -> AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> {
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
                    let currentPublisher: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> = supportedCurrencyProvider.supportedCurrencyPublisher(id: UUID().uuidString)
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
        supportedCurrencyPublisher()
            .subscribe(Subscribers.Sink(receiveCompletion: { _ in }, receiveValue: { _ in }))
    }
}

extension SupportedCurrencyManager {
    static let shared: SupportedCurrencyManager = SupportedCurrencyManager(
        supportedCurrencyProvider: Fetcher.shared,
        internalSerialDispatchQueue: DispatchQueue(label: "supported.currency.manager.internal.serial")
    )
}
