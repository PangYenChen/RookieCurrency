//
//  AppUtility + Reactive.swift
//  CombineCurrency
//
//  Created by 陳邦彥 on 2023/7/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

extension AppUtility{
    
    private static var wrappedSupportedSymbols: AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error>?
#warning("這裡應該會有同時性問題，等我讀完 concurrency 之後再處理")
    
    static func supportedSymbolsPublisher() -> AnyPublisher<[ResponseDataModel.CurrencyCode: String], Error> {
        if let supportedSymbols {
            return Just(supportedSymbols)
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        } else {
            if let wrappedSupportedSymbols {
                return wrappedSupportedSymbols
            } else {
                let wrappedSupportedSymbols = Fetcher.shared.publisher(for: Endpoints.SupportedSymbols())
                    .map { $0.symbols }
                    .handleEvents(
                        receiveOutput: { supportedSymbols in Self.supportedSymbols = supportedSymbols },
                        receiveCompletion: { _ in Self.wrappedSupportedSymbols = nil },
                        receiveCancel: { Self.wrappedSupportedSymbols = nil }
                    )
                    .eraseToAnyPublisher()
                
                Self.wrappedSupportedSymbols = wrappedSupportedSymbols
                
                return wrappedSupportedSymbols
            }
        }
    }
    
    static func start() {
        supportedSymbolsPublisher()
            .subscribe(Subscribers.Sink(receiveCompletion: { _ in }, receiveValue: { _ in }))
    }
}
