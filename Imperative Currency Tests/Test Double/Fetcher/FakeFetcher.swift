//
//  FakeFetcher.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/8/3.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

@testable import ImperativeCurrency

final class FakeFetcher: FetcherProtocol {
    
    private(set) var numberOfMethodCall = 0
    
    func fetch<Endpoint: EndpointProtocol>(
        _ endpoint: Endpoint,
        completionHandler: @escaping (Result<Endpoint.ResponseType, Swift.Error>) -> Void
    ){
        // This is a fake instance, and any of it's method should not be called.
        
        numberOfMethodCall += 1
    }
}
