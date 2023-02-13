#  Rookie Currency

這個 App 計算當下的匯率對於過去一段期間的平均匯率的升值或者貶值。

使用者可以輸入想參考的歷史資料的天數，透過 API 拿到歷史資料，拿到後儲存在本地，供日後使用。

這個 project 檔中有兩個 target，實作出的是同樣的邏輯，一個用 imperative 的方式寫，一個用 reactive(Combine) 的方式寫。

有實作多國語系，並將使用者帶到系統設定畫面更改語言。

使用R.swift。

使用SPM。

顯示的文字隨系統大小改變。

使用 Locale 顯示幣別的 localized string。

使用 diffable data source。

custom segue

讓使用者決定排序的方向。

若使用者在 present 的設定頁面未更改設定，阻止使用者下拉離開。
