//
//  TestDoubles.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/4/9.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

#if RookieCurrency_Tests
@testable import RookieCurrency
#else
@testable import CombineCurrency
#endif

enum TestDouble {}

extension TestDouble {
    enum SpyArchiver: ArchiverProtocol {
        
        static private(set) var numberOfArchiveCall = 0
        
        static private(set) var numberOfUnarchiveCall = 0
        
        static private var archivedFileNames: [String] = []
        
        static func reset() {
            numberOfArchiveCall = 0
            numberOfUnarchiveCall = 0
            archivedFileNames = []
        }
        
        static func archive(historicalRate: ResponseDataModel.HistoricalRate) throws {
            numberOfArchiveCall += 1
            
            archivedFileNames.append(historicalRate.dateString)
        }
        
        
        static func unarchive(historicalRateDateString fileName: String) throws -> ResponseDataModel.HistoricalRate {
            numberOfUnarchiveCall += 1
            
            return TestingData.historicalRate(dateString: fileName)
        }
        
        static func hasFileInDisk(historicalRateDateString fileName: String) -> Bool {
            archivedFileNames.contains(fileName)
        }
        
        static func removeAllStoredFile() throws {}
    }
}
