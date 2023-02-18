//
//  Publisher + Helper.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/18.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation
import Combine

extension Publisher {
    func convertOutputToResult() -> AnyPublisher<Result<Output, Failure>, Never> {
        map { output in Result<Output, Failure>.success(output) }
            .catch { failure in Just(Result<Output, Failure>.failure(failure)) }
            .eraseToAnyPublisher()
    }
    
    func resultFailure<Success, Failure>() -> AnyPublisher<Failure, Never>
    where Self.Output == Result<Success, Failure>,
          Self.Failure == Never
    {
        compactMap { result in
            guard case .failure(let failure) = result else { return nil }
            return failure
        }
        .eraseToAnyPublisher()
    }
}
