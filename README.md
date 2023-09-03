#  Rookie Currency

## 概觀

這個 App 計算當下的匯率對於過去一段期間的平均匯率的升值或者貶值。

使用者可以輸入想參考的歷史資料的天數，透過網路拿到歷史資料，拿到後儲存在本地，供日後使用。

這個 project 檔中有兩個 target，實作出的是同樣的邏輯，ImperativeCurrency 用 imperative 的方式寫；ReactiveCurrency 用 reactive(Combine) 的方式寫。

## 實作功能

- 多國語系，並將使用者帶到系統設定畫面更改語言（這是官方建議的做法）。

- 動態字級

- 使用 UISearchBar 搭配 UITableViewDiffableDataSource 實作搜尋功能及動畫。

- 使用裝置的 Locale 顯示貨幣本地化名稱。

- 客製化 segue

- 讓使用者決定貨幣的排序方向。

- 當使用者在 present 的設定頁面且未更改設定時，使用 UIAdaptivePresentationControllerDelegate 阻止下拉離開。

- 用 run script 在 build 之前拿到當下的 git commit hash 跟日期，在設定頁面顯示出來，以便除錯。

- 用 UserDefault 儲存使用者偏好。

- 使用 debug build configuration 時，顯示模擬器的路徑，以便查看儲存的資料跟 UserDefault。

- 在服務商回傳 status code 429(too many request) 時，更換 api key 重打。 

- 用 phantom type 區分雖然本質上一樣，但用途不同的 data model。

- 處理網路呼叫的物件使用 Generic type。

- 編寫單元測試

## 使用的第三方套件

- R.swift。

## 使用的套件管理工具

- Swift Package Manager
