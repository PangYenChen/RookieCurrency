//
//  AnalystTest.swift
//  RookieCurrencyTests
//
//  Created by 陳邦彥 on 2023/6/25.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import XCTest
#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif


final class AnalystTest: XCTestCase {

    func testSingleDay() throws {
        
        let currencyOfInterest: Set<ResponseDataModel.CurrencyCode> = ["USD", "EUR", "JPY", "GBP", "CNY", "CAD", "AUD", "CHF"]
        let dateString = "1970-01-01"
        let timestamp = Int.random(in: 0..<Int.max)
        let rates = ["AED": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "AFN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ALL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "AMD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ANG": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "AOA": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ARS": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "AUD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "AWG": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "AZN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BAM": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BBD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BDT": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BGN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BHD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BIF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BMD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BND": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BOB": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BRL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BSD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BTC": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BTN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BWP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BYN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BYR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "BZD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CAD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CDF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CHF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CLF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CLP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CNY": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "COP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CRC": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CUC": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CUP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CVE": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "CZK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "DJF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "DKK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "DOP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "DZD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "EGP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ERN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ETB": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "EUR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "FJD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "FKP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GBP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GEL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GGP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GHS": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GIP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GMD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GNF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GTQ": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "GYD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "HKD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "HNL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "HRK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "HTG": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "HUF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "IDR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ILS": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "IMP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "INR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "IQD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "IRR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ISK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "JEP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "JMD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "JOD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "JPY": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KES": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KGS": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KHR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KMF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KPW": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KRW": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KWD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KYD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "KZT": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "LAK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "LBP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "LKR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "LRD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "LSL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "LTL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "LVL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "LYD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MAD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MDL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MGA": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MKD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MMK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MNT": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MOP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MRO": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MUR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MVR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MWK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MXN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MYR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "MZN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "NAD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "NGN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "NIO": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "NOK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "NPR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "NZD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "OMR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "PAB": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "PEN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "PGK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "PHP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "PKR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "PLN": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "PYG": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "QAR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "RON": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "RSD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "RUB": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "RWF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SAR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SBD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SCR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SDG": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SEK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SGD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SHP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SLE": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SLL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SOS": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SRD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "STD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SVC": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SYP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "SZL": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "THB": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "TJS": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "TMT": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "TND": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "TOP": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "TRY": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "TTD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "TWD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "TZS": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "UAH": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "UGX": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "USD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "UYU": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "UZS": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "VEF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "VES": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "VND": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "VUV": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "WST": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "XAF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "XAG": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "XAU": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "XCD": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "XDR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "XOF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "XPF": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "YER": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ZAR": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ZMK": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ZMW": Double.random(in: 0..<Double.greatestFiniteMagnitude),
                     "ZWL": Double.random(in: 0..<Double.greatestFiniteMagnitude)]
        let latestRate = ResponseDataModel.LatestRate(dateString: dateString,
                                                      timestamp: timestamp,
                                                      rates: rates)
        let historicalRate = ResponseDataModel.HistoricalRate(dateString: dateString,
                                                              timestamp: timestamp,
                                                              rates: rates)
        let baseCurrency = "TWD"
        
        let analyzedData = Analyst.analyze(currencyOfInterest: currencyOfInterest,
                                           latestRate: latestRate,
                                           historicalRateSet: [historicalRate],
                                           baseCurrency: baseCurrency)
        
        analyzedData.forEach { _, result in
            switch result {
            case .success: break
            case .failure: XCTFail("這個情境中的 analyzed data 應該要都是成功的")
            }
        }
        
        let analyzedSuccess = analyzedData
            .compactMapValues { result in try? result.get() }
        
        currencyOfInterest.forEach { currencyCode in
            guard analyzedSuccess[currencyCode]?.mean == analyzedSuccess[currencyCode]?.latest else {
                XCTFail("這個情境只有一天的資料，所以平均跟當天的匯率應該要一樣。currency code: \(currencyCode), 過往平均匯率：\(String(describing: analyzedSuccess[currencyCode]?.mean)), 當天匯率：\(String(describing: analyzedSuccess[currencyCode]?.latest))")
                return
            }
            guard analyzedSuccess[currencyCode]?.deviation == 0 else {
                XCTFail("這個情境只有一天的資料，deviation 應該要是 0")
                return
            }
        }
        
    }
}
