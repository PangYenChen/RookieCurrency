#  Rookie Currency

## 概觀 Overview

The App calculates the appreciation or depreciation of the current exchange rate against the average exchange rate of the past period.

Users can input the number of days of historical data they want to refer to, get the historical data through the network, and then store it locally for future use.

There are two targets in this project file that implement the same logic, ImperativeCurrency is written in an imperative way and ReactiveCurrency is written in a reactive(Combine) way.

這個 App 計算當下的匯率對於過去一段期間的平均匯率的升值或者貶值。

使用者可以輸入想參考的歷史資料的天數，透過網路拿到歷史資料，拿到後儲存在本地，供日後使用。

這個 project 檔中有兩個 target，實作出的是同樣的邏輯，ImperativeCurrency 用 imperative 的方式寫；ReactiveCurrency 用 reactive(Combine) 的方式寫。

## 主要操作流程 Main flow

![Simulator Screen Recording - iPhone 14 Pro Max - 2023-09-06 at 19 49 59-min](https://github.com/PangYenChen/RookieCurrency/assets/50511308/67e21ce3-921d-46cb-a877-c50955016ef9)

- Updates data every 10 seconds on the Home screen.
    
    - Indicates to the user that an update is in progress, or how old the data is (the server updates about once a minute.)
    
- You can scroll down to update.
 
- Change the order in which data is displayed (ascending or descending in fluctuation).

- Search for currencies by currency name or currency code.

    - An animation is shown when filtering.

- After entering the setting scene:

    - Stop Automatic Updates
    
    - If there are no changes to the settings, scroll down to dismiss.
    
    - If there is a change to the setting, ask the user if they want to dismiss the change or save it when user scroll down.

- After changing the number of days under consideration, return to the main screen to recalculate the fluctuation. 

- Base currency and the currency of interest selecting page:

    - You can also scroll down to update (the currencies supported by the service provider) and search for them, with animation.
    
    - You can sort by currency name or currency code.
    
    - If the language is Chinese, you can sort by the Zhuyin of the currency name.

- If the user wants to change the language, bring the user to the system settings screen (official recommendation.)

- Dynamic character level support

- User can delete locally stored exchange rate data. 

- Troubleshooting information page:
    
    - The current api key quota usage.
    
    - Where the exchange rate data is stored.

- App version number, commit hash, commit time are displayed.

- After reopening the App, the previously changed settings will be retained.


- 在主畫面每 10 秒更新一次資料。
    
    - 提示使用者正在更新，或者資料是多久前的（伺服器大約一分鐘更新一次。）
    
- 可以下拉更新。
 
- 改變資料的顯示順序（依漲跌幅度遞增或遞減）

- 以貨幣名稱，或者貨幣代碼搜尋貨幣。

    - 篩選時有動畫。

- 進入設定頁面後：

    - 停止自動更新
    
    - 如果沒有變更設定，可以下拉 dismiss
    
    - 如果有變更設定，下拉時詢問使用者，要捨棄變更，還是要儲存變更。

- 改變考慮的天數後，回到主畫面重新計算漲跌幅度。 

- 選取基準貨幣頁面，以及選取感興趣的貨幣的頁面：

    - 同樣可以下拉更新（服務商支援的貨幣）跟搜尋，也有動畫。
    
    - 可以用貨幣名稱，或者貨幣代碼排序。
    
    - 語言為中文時可以用貨幣名稱的注音拼音排序

- 如果使用者想改語言，將使用者帶到系統設定畫面（官方建議做法。）

- 支援動態字級

- 使用者可以刪除本地儲存的匯率資料。 

- 除錯資訊頁面顯示：
    
    - 目前 api key 的額度的用量
    
    - 匯率資料儲存的位置

- 顯示 App 版本號、commit hash、commit 時間

- 重新開啟 App 後，先前改變的設定會保留。

## 實作功能 Feature

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

- Change the api key and make an api call again when the vender returns status code 429 (too many requests).
 
- Unit Tests


- 使用裝置的 Locale 顯示貨幣本地化名稱。

- 將拿到的匯率資料存在裝置本地，之後更新資料時，只需要向伺服器請求當下的匯率，不需要請求過往匯率。

- 客製化 segue

- 當使用者在 present 的設定頁面且未更改設定時，使用 UIAdaptivePresentationControllerDelegate 阻止下拉離開。

- 多國語系

- 動態字級

- 用 run script 在 build 時候拿當下的 git commit hash 跟日期，在設定頁面顯示出來，以便除錯。

- 使用 debug build configuration 時，顯示模擬器的路徑，以便查看儲存的資料跟 UserDefault。

- 用 UserDefault 儲存使用者偏好。

- 用 phantom type 區分雖然本質上一樣，但用途不同的 data model。

- 處理網路呼叫的物件使用 Generic type。

- 在服務商回傳 status code 429(too many request) 時，更換 api key 重打。
 
- 編寫單元測試

## 使用的第三方套件 Third-party package

- R.swift。

## 使用的套件管理工具 Thrid-party package manager

- Swift Package Manager
