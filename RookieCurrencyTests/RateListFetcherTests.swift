//
//  RookieCurrencyTests.swift
//  RookieCurrencyTests
//
//  Created by Pang-yen Chen on 2020/5/20.
//  Copyright © 2020 Pang-yen Chen. All rights reserved.
//

import XCTest
@testable import RookieCurrency

class RateListFetcherTests: XCTestCase {
    
    var sut: RateListFetcher!
    
    override func setUp() {
        sut = RateListFetcher(rookieURLSession: RookieURLSessionStub.init())
    }
    
    override func tearDown() {
        sut = nil
    }
    
    func testAPICallQuota() {
#warning("要改名字")
        let dummyEndpoint = RateListFetcher.EndPoint.latest
        
        let expectation = expectation(description: "拿到 rate list")
        
        sut.fetchRateList(for: dummyEndpoint) { result in
            switch result {
            case .success(let rateList):
                assert(!(rateList.rates.isEmpty))
                expectation.fulfill()
            case .failure:
                XCTFail()
            }
        }
        
        wait(for: [expectation], timeout: 3)
    }
}

class RookieURLSessionStub: RookieURLSession {
    
    
    func rookieDataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        completionHandler(data, nil, nil)
    }
    
    let data = """
{
  "success": true,
  "timestamp": 1676505599,
  "historical": true,
  "base": "EUR",
  "date": "2023-02-15",
  "rates": {
    "AED": 3.927273,
    "AFN": 95.828248,
    "ALL": 115.911468,
    "AMD": 423.847367,
    "ANG": 1.931372,
    "AOA": 542.630269,
    "ARS": 205.700494,
    "AUD": 1.547873,
    "AWG": 1.92723,
    "AZN": 1.820809,
    "BAM": 1.956852,
    "BBD": 2.16383,
    "BDT": 113.86596,
    "BGN": 1.955989,
    "BHD": 0.40313,
    "BIF": 2225.279592,
    "BMD": 1.069198,
    "BND": 1.430007,
    "BOB": 7.405267,
    "BRL": 5.580679,
    "BSD": 1.07166,
    "BTC": 4.3960891e-05,
    "BTN": 88.733436,
    "BWP": 14.045503,
    "BYN": 2.705013,
    "BYR": 20956.287264,
    "BZD": 2.160228,
    "CAD": 1.431763,
    "CDF": 2188.649526,
    "CHF": 0.987309,
    "CLF": 0.030694,
    "CLP": 846.943904,
    "CNY": 7.327173,
    "COP": 5157.748591,
    "CRC": 609.106679,
    "CUC": 1.069198,
    "CUP": 28.333756,
    "CVE": 110.32261,
    "CZK": 23.637729,
    "DJF": 190.80964,
    "DKK": 7.450746,
    "DOP": 60.216318,
    "DZD": 146.239714,
    "EGP": 32.655022,
    "ERN": 16.037975,
    "ETB": 57.589496,
    "EUR": 1,
    "FJD": 2.341226,
    "FKP": 0.879742,
    "GBP": 0.888173,
    "GEL": 2.833041,
    "GGP": 0.879742,
    "GHS": 13.262025,
    "GIP": 0.879742,
    "GMD": 65.333162,
    "GNF": 9228.046221,
    "GTQ": 8.391203,
    "GYD": 226.128083,
    "HKD": 8.389444,
    "HNL": 26.356121,
    "HRK": 7.542974,
    "HTG": 161.010561,
    "HUF": 379.991238,
    "IDR": 16267.852588,
    "ILS": 3.773746,
    "IMP": 0.879742,
    "INR": 88.46665,
    "IQD": 1561.564161,
    "IRR": 45173.629628,
    "ISK": 153.900797,
    "JEP": 0.879742,
    "JMD": 165.437296,
    "JOD": 0.758485,
    "JPY": 143.185976,
    "KES": 134.60099,
    "KGS": 92.987859,
    "KHR": 4378.763706,
    "KMF": 492.84664,
    "KPW": 962.199602,
    "KRW": 1372.952256,
    "KWD": 0.327592,
    "KYD": 0.893058,
    "KZT": 479.085695,
    "LAK": 18096.18181,
    "LBP": 16305.274149,
    "LKR": 391.163163,
    "LRD": 168.188514,
    "LSL": 19.288233,
    "LTL": 3.157064,
    "LVL": 0.646748,
    "LYD": 5.136382,
    "MAD": 11.025563,
    "MDL": 20.067179,
    "MGA": 4599.608872,
    "MKD": 61.647192,
    "MMK": 2250.527414,
    "MNT": 3759.220503,
    "MOP": 8.663443,
    "MRO": 381.70362,
    "MUR": 48.913583,
    "MVR": 16.422879,
    "MWK": 1099.956816,
    "MXN": 19.871041,
    "MYR": 4.69645,
    "MZN": 67.468585,
    "NAD": 19.288475,
    "NGN": 493.432618,
    "NIO": 38.865729,
    "NOK": 10.917974,
    "NPR": 141.970481,
    "NZD": 1.701393,
    "OMR": 0.41165,
    "PAB": 1.07166,
    "PEN": 4.11802,
    "PGK": 3.776101,
    "PHP": 59.244317,
    "PKR": 284.256391,
    "PLN": 4.763953,
    "PYG": 7800.473366,
    "QAR": 3.89299,
    "RON": 4.899152,
    "RSD": 117.31281,
    "RUB": 79.12082,
    "RWF": 1163.705913,
    "SAR": 4.010894,
    "SBD": 0.130979,
    "SCR": 14.364052,
    "SDG": 624.412138,
    "SEK": 11.140052,
    "SGD": 1.427856,
    "SHP": 1.300947,
    "SLE": 21.231997,
    "SLL": 21116.667437,
    "SOS": 608.907379,
    "SRD": 34.791178,
    "STD": 22130.246724,
    "SVC": 9.376809,
    "SYP": 2686.227649,
    "SZL": 19.267311,
    "THB": 36.653233,
    "TJS": 11.188238,
    "TMT": 3.752886,
    "TND": 3.336186,
    "TOP": 2.492732,
    "TRY": 20.16137,
    "TTD": 7.27223,
    "TWD": 32.414855,
    "TZS": 2493.369977,
    "UAH": 39.578027,
    "UGX": 3933.05382,
    "USD": 1.069198,
    "UYU": 41.832453,
    "UZS": 12183.90237,
    "VEF": 2587003.091159,
    "VES": 25.840922,
    "VND": 25259.810541,
    "VUV": 125.287952,
    "WST": 2.869007,
    "XAF": 656.287434,
    "XAG": 0.049412,
    "XAU": 0.000582,
    "XCD": 2.889561,
    "XDR": 0.79871,
    "XOF": 656.299716,
    "XPF": 119.375856,
    "YER": 267.633906,
    "ZAR": 19.28396,
    "ZMK": 9624.070263,
    "ZMW": 20.710215,
    "ZWL": 344.281426
  }
}
""".data(using: .utf8)!
}
