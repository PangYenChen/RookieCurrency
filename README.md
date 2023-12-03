#  Rookie Currency

> Language Switch: [繁體中文](https://github.com/PangYenChen/RookieCurrency/blob/main/README_CN.md).

## Overview

The App calculates the appreciation or depreciation of the current exchange rate against the average exchange rate of the past period.

Users can input the number of days of historical data they want to refer to, get the historical data through the network, and then store it locally for future use.

There are two targets in this project file that implement the same logic. ImperativeCurrency is written in an imperative way and ReactiveCurrency is written in a reactive(Combine) way.

## Main flow

![Simulator Screen Recording - iPhone 14 Pro Max - 2023-09-06 at 19 49 59-min](https://github.com/PangYenChen/RookieCurrency/assets/50511308/67e21ce3-921d-46cb-a877-c50955016ef9)

- Update data every 10 seconds on the Home screen.
    
    - Indicates to the user that an update is in progress, or how old the data is (the server updates about once a minute.)
    
- You can scroll down to update.
 
- Change the order in which data is displayed (ascending or descending in fluctuation).

- Search for currencies by currency name or currency code.

    - An animation is shown when filtering.

- After entering the setting scene:

    - Stop Automatic Updates
    
    - If there are no changes to the settings, scroll down to dismiss.
    
    - If there is a change to the setting, ask the user if they want to dismiss the change or save it when the user scrolls down.

- After changing the number of days under consideration, return to the main screen to recalculate the fluctuation. 

- Base currency and the currency of interest selecting page:

    - You can also scroll down to update (the currencies supported by the service provider) and search for them, with animation.
    
    - You can sort by currency name or currency code.
    
    - If the language is Chinese, you can sort by the Zhuyin of the currency name.

- If the user wants to change the language, bring the user to the system settings screen (official recommendation.)

- Dynamic character level support

- User can delete locally stored exchange rate data. 

- Troubleshooting information page:
    
    - The current API key quota usage.
    
    - Where the exchange rate data is stored.

- App version number, commit hash, and commit time are displayed.

- After reopening the App, the previously changed settings will be retained.

## Feature

- Use the device's Locale to display the currency localization name.

- By storing the obtained exchange rate data locally on the device, when updating the data in the future, you only need to request the current exchange rate from the server, not the past exchange rate.

- Customized segue

- Use UIAdaptivePresentationControllerDelegate to block the dropdown when the user is on the presenting settings page and has not changed the settings.

- Localization

- Support for Dynamic Type

- Use the run script to get the current git commit hash and date when building, and display it on the setting page for debugging.

- When using debug build configuration, show the path of the simulator so you can see the data you save.

- Save user preferences with UserDefault.

- Use phantom type to distinguish between data models that are essentially the same but have different uses.

- Use Generic type for objects that handle network calls.

- Change the API key and make an API call again when the vendor returns status code 429 (too many requests).
 
- Unit Tests

## Third-party package

- R.swift

- SwiftLint
    - Using Regex to define a custom rule

- SFSafeSymbols

## Thrid-party package manager

- Swift Package Manager
