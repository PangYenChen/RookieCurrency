//
//  Rate.swift
//  RookieCurrency
//
//  Created by 陳邦彥 on 2023/2/28.
//  Copyright © 2023 Pang-yen Chen. All rights reserved.
//

import Foundation

#if IMPERATIVE_CURRENCY_TESTS
@testable import ImperativeCurrency
#else
@testable import ReactiveCurrency
#endif

extension TestingData {
    
    static func historicalRateDataFor(dateString: String) -> Data? {
        
        guard let timestamp = AppUtility.requestDateFormatter.date(from: dateString)
            .map({ Int($0.timeIntervalSince1970) })
            .map(String.init(describing:)) else { return nil }
        
        return """
{
  "base": "USD",
  "date": "\(dateString)",
  "historical": true,
  "rates": {
    "AED": 3.673102,
    "AFN": 89.999946,
    "ALL": 106.349632,
    "AMD": 396.0403,
    "ANG": 1.802075,
    "AOA": 504.274898,
    "ARS": 187.583605,
    "AUD": 1.41356,
    "AWG": 1.8,
    "AZN": 1.698675,
    "BAM": 1.77793,
    "BBD": 2.018909,
    "BDT": 107.339254,
    "BGN": 1.792876,
    "BHD": 0.376997,
    "BIF": 2070,
    "BMD": 1,
    "BND": 1.306217,
    "BOB": 6.90958,
    "BRL": 5.050703,
    "BSD": 0.999909,
    "BTC": 4.2634658e-05,
    "BTN": 82.154786,
    "BWP": 12.689801,
    "BYN": 2.523771,
    "BYR": 19600,
    "BZD": 2.015545,
    "CAD": 1.331735,
    "CDF": 2044.99968,
    "CHF": 0.913397,
    "CLF": 0.028268,
    "CLP": 780.000143,
    "CNY": 6.7325,
    "COP": 4587,
    "CRC": 553.736364,
    "CUC": 1,
    "CUP": 26.5,
    "CVE": 101.350169,
    "CZK": 21.76603,
    "DJF": 177.720321,
    "DKK": 6.824149,
    "DOP": 56.650114,
    "DZD": 135.417412,
    "EGP": 30.281802,
    "ERN": 15,
    "ETB": 53.506879,
    "EUR": 0.91703,
    "FJD": 2.173987,
    "FKP": 0.812538,
    "GBP": 0.818197,
    "GEL": 2.629755,
    "GGP": 0.812538,
    "GHS": 12.250311,
    "GIP": 0.812538,
    "GMD": 60.999964,
    "GNF": 8800.000109,
    "GTQ": 7.849383,
    "GYD": 210.984695,
    "HKD": 7.84465,
    "HNL": 24.620112,
    "HRK": 7.042198,
    "HTG": 149.987727,
    "HUF": 353.314959,
    "IDR": 14895.5,
    "ILS": 3.39055,
    "IMP": 0.812538,
    "INR": 82.04615,
    "IQD": 1460.5,
    "IRR": 42200.000118,
    "ISK": 140.730041,
    "JEP": 0.812538,
    "JMD": 153.769927,
    "JOD": 0.709398,
    "JPY": 128.751502,
    "KES": 124.696363,
    "KGS": 86.2206,
    "KHR": 4109.999977,
    "KMF": 451.297745,
    "KPW": 899.98113,
    "KRW": 1225.249715,
    "KWD": 0.30511,
    "KYD": 0.833295,
    "KZT": 458.702253,
    "LAK": 16834.9997,
    "LBP": 15480.000064,
    "LKR": 365.983436,
    "LRD": 156.949945,
    "LSL": 17.089608,
    "LTL": 2.95274,
    "LVL": 0.60489,
    "LYD": 4.730227,
    "MAD": 10.1705,
    "MDL": 18.792611,
    "MGA": 4285.000501,
    "MKD": 56.485289,
    "MMK": 2099.904725,
    "MNT": 3466.729705,
    "MOP": 8.078038,
    "MRO": 356.999828,
    "MUR": 44.496401,
    "MVR": 15.350198,
    "MWK": 1020.999642,
    "MXN": 18.656398,
    "MYR": 4.246055,
    "MZN": 63.830118,
    "NAD": 17.089947,
    "NGN": 460.539756,
    "NIO": 36.349938,
    "NOK": 10.04929,
    "NPR": 131.447221,
    "NZD": 1.54406,
    "OMR": 0.385,
    "PAB": 0.999909,
    "PEN": 3.820396,
    "PGK": 3.524985,
    "PHP": 53.860204,
    "PKR": 270.650045,
    "PLN": 4.295782,
    "PYG": 7292.842792,
    "QAR": 3.641044,
    "RON": 4.497595,
    "RSD": 107.634985,
    "RUB": 75.065987,
    "RWF": 1092.5,
    "SAR": 3.752536,
    "SBD": 8.197272,
    "SCR": 13.94948,
    "SDG": 584.502165,
    "SEK": 10.38495,
    "SGD": 1.310605,
    "SHP": 1.377403,
    "SLE": 19.883776,
    "SLL": 19450.000089,
    "SOS": 568.502706,
    "SRD": 32.000327,
    "STD": 20697.981008,
    "SVC": 8.74921,
    "SYP": 2512.533601,
    "SZL": 17.08997,
    "THB": 33.060311,
    "TJS": 10.288712,
    "TMT": 3.51,
    "TND": 3.040498,
    "TOP": 2.31735,
    "TRY": 18.81714,
    "TTD": 6.786851,
    "TWD": 29.573027,
    "TZS": 2331.999934,
    "UAH": 36.746814,
    "UGX": 3683.693785,
    "USD": 1,
    "UYU": 38.691466,
    "UZS": 11300.000131,
    "VEF": 2234550.370978,
    "VES": 22.652449,
    "VND": 23450,
    "VUV": 115.705491,
    "WST": 2.661798,
    "XAF": 596.340809,
    "XAG": 0.042597,
    "XAU": 0.000522,
    "XCD": 2.70255,
    "XDR": 0.739838,
    "XOF": 602.999762,
    "XPF": 109.630227,
    "YER": 250.404736,
    "ZAR": 17.084018,
    "ZMK": 9001.197048,
    "ZMW": 19.099244,
    "ZWL": 321.999592
  },
  "success": true,
  "timestamp": \(timestamp)
}
""".data(using: .utf8)
    }
    
    static let latestData = """
{
  "base": "USD",
  "date": "2023-03-11",
  "rates": {
    "AED": 3.67265,
    "AFN": 87.575743,
    "ALL": 107.219691,
    "AMD": 385.833059,
    "ANG": 1.792945,
    "AOA": 507.503981,
    "ARS": 199.375934,
    "AUD": 1.52045,
    "AWG": 1.8025,
    "AZN": 1.70397,
    "BAM": 1.837381,
    "BBD": 2.008643,
    "BDT": 104.87106,
    "BGN": 1.833405,
    "BHD": 0.377108,
    "BIF": 2068.392127,
    "BMD": 1,
    "BND": 1.347832,
    "BOB": 6.873972,
    "BRL": 5.217104,
    "BSD": 0.994786,
    "BTC": 4.8547668e-05,
    "BTN": 81.590117,
    "BWP": 13.229367,
    "BYN": 2.511062,
    "BYR": 19600,
    "BZD": 2.005261,
    "CAD": 1.38595,
    "CDF": 2051.000362,
    "CHF": 0.923965,
    "CLF": 0.028874,
    "CLP": 796.720396,
    "CNY": 6.906204,
    "COP": 4718.37,
    "CRC": 545.35206,
    "CUC": 1,
    "CUP": 26.5,
    "CVE": 103.584011,
    "CZK": 22.209104,
    "DJF": 177.133731,
    "DKK": 6.99504,
    "DOP": 54.892198,
    "DZD": 136.615139,
    "EGP": 30.749049,
    "ERN": 15,
    "ETB": 53.516088,
    "EUR": 0.938304,
    "FJD": 2.236704,
    "FKP": 0.838892,
    "GBP": 0.830979,
    "GEL": 2.580391,
    "GGP": 0.838892,
    "GHS": 12.286157,
    "GIP": 0.838892,
    "GMD": 61.25039,
    "GNF": 8564.986613,
    "GTQ": 7.769271,
    "GYD": 209.911222,
    "HKD": 7.84995,
    "HNL": 24.533797,
    "HRK": 7.054794,
    "HTG": 152.670393,
    "HUF": 360.040388,
    "IDR": 15503,
    "ILS": 3.58575,
    "IMP": 0.838892,
    "INR": 82.01855,
    "IQD": 1451.923529,
    "IRR": 42275.000352,
    "ISK": 141.280386,
    "JEP": 0.838892,
    "JMD": 152.181878,
    "JOD": 0.709404,
    "JPY": 134.99504,
    "KES": 129.603804,
    "KGS": 87.420385,
    "KHR": 4025.553103,
    "KMF": 461.850384,
    "KPW": 900.006894,
    "KRW": 1320.640384,
    "KWD": 0.30696,
    "KYD": 0.829067,
    "KZT": 449.762788,
    "LAK": 16785.194232,
    "LBP": 14932.406407,
    "LKR": 323.340692,
    "LRD": 160.503775,
    "LSL": 18.245039,
    "LTL": 2.95274,
    "LVL": 0.60489,
    "LYD": 4.825966,
    "MAD": 10.336982,
    "MDL": 18.652825,
    "MGA": 4280.144676,
    "MKD": 57.889051,
    "MMK": 2089.154023,
    "MNT": 3538.038767,
    "MOP": 8.043497,
    "MRO": 356.999828,
    "MUR": 47.060379,
    "MVR": 15.360378,
    "MWK": 1011.790126,
    "MXN": 18.49315,
    "MYR": 4.519504,
    "MZN": 63.103732,
    "NAD": 18.355039,
    "NGN": 460.520377,
    "NIO": 36.384988,
    "NOK": 10.677905,
    "NPR": 130.544413,
    "NZD": 1.631322,
    "OMR": 0.385096,
    "PAB": 0.99488,
    "PEN": 3.765231,
    "PGK": 3.506036,
    "PHP": 55.180375,
    "PKR": 279.220255,
    "PLN": 4.39745,
    "PYG": 7161.444878,
    "QAR": 3.641038,
    "RON": 4.618804,
    "RSD": 110.022651,
    "RUB": 76.20369,
    "RWF": 1086.664475,
    "SAR": 3.75393,
    "SBD": 8.198925,
    "SCR": 13.037636,
    "SDG": 594.00034,
    "SEK": 10.70418,
    "SGD": 1.348804,
    "SHP": 1.21675,
    "SLE": 20.721737,
    "SLL": 19750.000338,
    "SOS": 569.503664,
    "SRD": 34.477038,
    "STD": 20697.981008,
    "SVC": 8.704965,
    "SYP": 2512.005964,
    "SZL": 18.23383,
    "THB": 34.820369,
    "TJS": 10.863545,
    "TMT": 3.51,
    "TND": 3.122038,
    "TOP": 2.36955,
    "TRY": 18.974604,
    "TTD": 6.761238,
    "TWD": 30.843038,
    "TZS": 2341.000335,
    "UAH": 36.718023,
    "UGX": 3697.68425,
    "USD": 1,
    "UYU": 38.977876,
    "UZS": 11331.673634,
    "VEF": 2411552.800016,
    "VES": 24.104859,
    "VND": 23675,
    "VUV": 120.10517,
    "WST": 2.753832,
    "XAF": 616.280708,
    "XAG": 0.048694,
    "XAU": 0.000535,
    "XCD": 2.70255,
    "XDR": 0.747992,
    "XOF": 616.280708,
    "XPF": 112.250364,
    "YER": 250.325037,
    "ZAR": 18.321765,
    "ZMK": 9001.203589,
    "ZMW": 20.095824,
    "ZWL": 321.999592
  },
  "success": true,
  "timestamp": 1678501623
}
""".data(using: .utf8)
    
    static let tooManyRequestData: Data? = """
{
  "message": "You have exceeded your daily/monthly API rate limit. Please review and upgrade your subscription plan at https://promptapi.com/subscriptions to continue."
}
""".data(using: .utf8)
    
    static let invalidAPIKeyData: Data? = """
Invalid authentication credentials
""".data(using: .utf8)
    
    static let supportedSymbols: Data? = """
{
  "success" : true,
  "symbols" : {
    "HRK" : "Croatian Kuna",
    "HUF" : "Hungarian Forint",
    "CDF" : "Congolese Franc",
    "ILS" : "Israeli New Sheqel",
    "NGN" : "Nigerian Naira",
    "GYD" : "Guyanaese Dollar",
    "BYR" : "Belarusian Ruble",
    "BHD" : "Bahraini Dinar",
    "SZL" : "Swazi Lilangeni",
    "INR" : "Indian Rupee",
    "SDG" : "Sudanese Pound",
    "PEN" : "Peruvian Nuevo Sol",
    "EUR" : "Euro",
    "QAR" : "Qatari Rial",
    "PGK" : "Papua New Guinean Kina",
    "LRD" : "Liberian Dollar",
    "ISK" : "Icelandic Króna",
    "SYP" : "Syrian Pound",
    "TRY" : "Turkish Lira",
    "UAH" : "Ukrainian Hryvnia",
    "SGD" : "Singapore Dollar",
    "MMK" : "Myanma Kyat",
    "NIO" : "Nicaraguan Córdoba",
    "BIF" : "Burundian Franc",
    "AFN" : "Afghan Afghani",
    "LKR" : "Sri Lankan Rupee",
    "GTQ" : "Guatemalan Quetzal",
    "CHF" : "Swiss Franc",
    "THB" : "Thai Baht",
    "AMD" : "Armenian Dram",
    "AOA" : "Angolan Kwanza",
    "SEK" : "Swedish Krona",
    "SAR" : "Saudi Riyal",
    "KWD" : "Kuwaiti Dinar",
    "IRR" : "Iranian Rial",
    "WST" : "Samoan Tala",
    "BGN" : "Bulgarian Lev",
    "BMD" : "Bermudan Dollar",
    "PHP" : "Philippine Peso",
    "XAF" : "CFA Franc BEAC",
    "ZMW" : "Zambian Kwacha",
    "BDT" : "Bangladeshi Taka",
    "NOK" : "Norwegian Krone",
    "BOB" : "Bolivian Boliviano",
    "TZS" : "Tanzanian Shilling",
    "BND" : "Brunei Dollar",
    "VEF" : "Venezuelan Bolívar Fuerte",
    "ANG" : "Netherlands Antillean Guilder",
    "SCR" : "Seychellois Rupee",
    "VUV" : "Vanuatu Vatu",
    "XAG" : "Silver (troy ounce)",
    "XCD" : "East Caribbean Dollar",
    "KYD" : "Cayman Islands Dollar",
    "DJF" : "Djiboutian Franc",
    "CLF" : "Chilean Unit of Account (UF)",
    "LSL" : "Lesotho Loti",
    "MOP" : "Macanese Pataca",
    "ALL" : "Albanian Lek",
    "SLE" : "Sierra Leonean Leone",
    "UZS" : "Uzbekistan Som",
    "PLN" : "Polish Zloty",
    "UYU" : "Uruguayan Peso",
    "LTL" : "Lithuanian Litas",
    "LYD" : "Libyan Dinar",
    "JPY" : "Japanese Yen",
    "MNT" : "Mongolian Tugrik",
    "FJD" : "Fijian Dollar",
    "ZWL" : "Zimbabwean Dollar",
    "KPW" : "North Korean Won",
    "PKR" : "Pakistani Rupee",
    "MRO" : "Mauritanian Ouguiya",
    "GBP" : "British Pound Sterling",
    "OMR" : "Omani Rial",
    "LVL" : "Latvian Lats",
    "SHP" : "Saint Helena Pound",
    "GEL" : "Georgian Lari",
    "TND" : "Tunisian Dinar",
    "DKK" : "Danish Krone",
    "KRW" : "South Korean Won",
    "NPR" : "Nepalese Rupee",
    "BSD" : "Bahamian Dollar",
    "CRC" : "Costa Rican Colón",
    "EGP" : "Egyptian Pound",
    "AUD" : "Australian Dollar",
    "BTC" : "Bitcoin",
    "MAD" : "Moroccan Dirham",
    "SLL" : "Sierra Leonean Leone",
    "MWK" : "Malawian Kwacha",
    "RSD" : "Serbian Dinar",
    "NZD" : "New Zealand Dollar",
    "SRD" : "Surinamese Dollar",
    "CLP" : "Chilean Peso",
    "RUB" : "Russian Ruble",
    "HKD" : "Hong Kong Dollar",
    "NAD" : "Namibian Dollar",
    "GMD" : "Gambian Dalasi",
    "VES" : "Sovereign Bolivar",
    "LAK" : "Laotian Kip",
    "VND" : "Vietnamese Dong",
    "CUC" : "Cuban Convertible Peso",
    "RON" : "Romanian Leu",
    "MUR" : "Mauritian Rupee",
    "XAU" : "Gold (troy ounce)",
    "GGP" : "Guernsey Pound",
    "BRL" : "Brazilian Real",
    "MXN" : "Mexican Peso",
    "STD" : "São Tomé and Príncipe Dobra",
    "AWG" : "Aruban Florin",
    "MVR" : "Maldivian Rufiyaa",
    "PAB" : "Panamanian Balboa",
    "TJS" : "Tajikistani Somoni",
    "GNF" : "Guinean Franc",
    "MGA" : "Malagasy Ariary",
    "XDR" : "Special Drawing Rights",
    "ETB" : "Ethiopian Birr",
    "COP" : "Colombian Peso",
    "ZAR" : "South African Rand",
    "IDR" : "Indonesian Rupiah",
    "SVC" : "Salvadoran Colón",
    "CVE" : "Cape Verdean Escudo",
    "TTD" : "Trinidad and Tobago Dollar",
    "GIP" : "Gibraltar Pound",
    "PYG" : "Paraguayan Guarani",
    "MZN" : "Mozambican Metical",
    "FKP" : "Falkland Islands Pound",
    "KZT" : "Kazakhstani Tenge",
    "UGX" : "Ugandan Shilling",
    "USD" : "United States Dollar",
    "ARS" : "Argentine Peso",
    "GHS" : "Ghanaian Cedi",
    "RWF" : "Rwandan Franc",
    "DOP" : "Dominican Peso",
    "JEP" : "Jersey Pound",
    "LBP" : "Lebanese Pound",
    "BTN" : "Bhutanese Ngultrum",
    "BZD" : "Belize Dollar",
    "MYR" : "Malaysian Ringgit",
    "YER" : "Yemeni Rial",
    "JMD" : "Jamaican Dollar",
    "TOP" : "Tongan Paʻanga",
    "SOS" : "Somali Shilling",
    "TMT" : "Turkmenistani Manat",
    "MDL" : "Moldovan Leu",
    "XOF" : "CFA Franc BCEAO",
    "TWD" : "New Taiwan Dollar",
    "BBD" : "Barbadian Dollar",
    "CAD" : "Canadian Dollar",
    "CNY" : "Chinese Yuan",
    "JOD" : "Jordanian Dinar",
    "XPF" : "CFP Franc",
    "IQD" : "Iraqi Dinar",
    "HNL" : "Honduran Lempira",
    "AED" : "United Arab Emirates Dirham",
    "ERN" : "Eritrean Nakfa",
    "KES" : "Kenyan Shilling",
    "KMF" : "Comorian Franc",
    "DZD" : "Algerian Dinar",
    "MKD" : "Macedonian Denar",
    "CUP" : "Cuban Peso",
    "BWP" : "Botswanan Pula",
    "AZN" : "Azerbaijani Manat",
    "SBD" : "Solomon Islands Dollar",
    "BYN" : "New Belarusian Ruble",
    "KGS" : "Kyrgystani Som",
    "KHR" : "Cambodian Riel",
    "ZMK" : "Zambian Kwacha (pre-2013)",
    "HTG" : "Haitian Gourde",
    "CZK" : "Czech Republic Koruna",
    "BAM" : "Bosnia-Herzegovina Convertible Mark",
    "IMP" : "Manx pound"
  }
}
""".data(using: .utf8)
}

