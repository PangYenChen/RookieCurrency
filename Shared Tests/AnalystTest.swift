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
        let rates = ["AED": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "AFN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ALL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "AMD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ANG": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "AOA": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ARS": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "AUD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "AWG": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "AZN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BAM": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BBD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BDT": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BGN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BHD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BIF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BMD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BND": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BOB": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BRL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BSD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BTC": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BTN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BWP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BYN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BYR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "BZD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CAD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CDF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CHF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CLF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CLP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CNY": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "COP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CRC": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CUC": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CUP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CVE": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "CZK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "DJF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "DKK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "DOP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "DZD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "EGP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ERN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ETB": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "EUR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "FJD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "FKP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GBP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GEL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GGP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GHS": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GIP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GMD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GNF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GTQ": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "GYD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "HKD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "HNL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "HRK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "HTG": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "HUF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "IDR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ILS": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "IMP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "INR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "IQD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "IRR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ISK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "JEP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "JMD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "JOD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "JPY": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KES": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KGS": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KHR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KMF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KPW": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KRW": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KWD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KYD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "KZT": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "LAK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "LBP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "LKR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "LRD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "LSL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "LTL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "LVL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "LYD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MAD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MDL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MGA": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MKD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MMK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MNT": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MOP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MRO": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MUR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MVR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MWK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MXN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MYR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "MZN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "NAD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "NGN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "NIO": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "NOK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "NPR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "NZD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "OMR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "PAB": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "PEN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "PGK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "PHP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "PKR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "PLN": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "PYG": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "QAR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "RON": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "RSD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "RUB": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "RWF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SAR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SBD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SCR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SDG": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SEK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SGD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SHP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SLE": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SLL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SOS": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SRD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "STD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SVC": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SYP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "SZL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "THB": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "TJS": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "TMT": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "TND": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "TOP": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "TRY": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "TTD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "TWD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "TZS": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "UAH": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "UGX": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "USD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "UYU": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "UZS": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "VEF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "VES": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "VND": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "VUV": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "WST": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "XAF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "XAG": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "XAU": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "XCD": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "XDR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "XOF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "XPF": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "YER": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ZAR": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ZMK": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ZMW": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude)),
                     "ZWL": Decimal(Double.random(in: 0..<Double.greatestFiniteMagnitude))]
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
