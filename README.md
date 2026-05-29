# 發票對對碰 — Invoice Swipe Game

<p align="center">
  <img src="logo.png" alt="發票對對碰" width="120" />
</p>

<p align="center">
  台灣統一發票樂透主題的 iOS 滑動配對遊戲<br/>
  Taiwan Receipt Lottery · Swipe · Score
</p>

<p align="center">
  <img src="https://img.shields.io/badge/iOS-16.0%2B-blue?logo=apple" />
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" />
  <img src="https://img.shields.io/badge/SwiftUI-✓-brightgreen" />
  <img src="https://img.shields.io/badge/version-2.0.0-lightgrey" />
  <img src="https://img.shields.io/badge/license-MIT-informational" />
</p>

---

## 🎮 遊戲介紹

**發票對對碰**是一款以台灣統一發票對獎為主題的 iOS 休閒遊戲。畫面上會出現一張張模擬發票，玩家必須快速判斷該張發票是否中獎——向右滑「中獎」、向左滑「未中獎」——在時間壓力或有限生命中衝高分數。三種遊戲模式各有不同玩法，配合 Game Center 全球排行榜與每日挑戰機制，讓每次遊玩都有新鮮感。

---

## 🕹️ 遊戲模式

### 一般模式 ⏱

- **時間**：30 秒限時
- **計分**：本局中獎總金額（NT$）
- **連勝機制**：連續答對且題目為中獎發票時累積連勝數，觸發特效與音效里程碑（×5、×10、×20…）
- **排行榜**：全時段全球最高單局獎金（NT$）

### 每日挑戰 📅

- **時間**：30 秒限時
- **次數**：每日限 3 次，至多保留當日最佳
- **同步**：以日期（YYYYMMDD）為 RNG 種子，全球玩家當天面對相同 5 組獎號
- **計分**：`發票總獎金 × (正確率 / 100)`，強調準確度
- **排行榜**：當日排行，每日重置

### 無限模式 ♾️

- **生命**：3 條命，答錯或倒數計時歸零各扣一條命
- **燃燒計時器**：每張卡片有獨立倒數，隨連勝加速
  - 連勝 0–4：8 秒 / 張
  - 連勝 5–9：6 秒 / 張
  - 連勝 10–19：4 秒 / 張
  - 連勝 20+：3 秒 / 張
- **計分**：以最高連勝數作為排名依據
- **排行榜**：全時段全球最高連勝（Combo ×N）

---

## 🎯 對獎規則

| 獎項 | 對應位數 | 獎金 | 大獎特效 |
|------|----------|------|----------|
| 特別獎 | 後 8 碼完整相符 | NT$ 10,000,000 | ✓ |
| 特獎 | 後 8 碼完整相符 | NT$ 2,000,000 | ✓ |
| 頭獎 | 後 8 碼完整相符 | NT$ 200,000 | ✓ |
| 二獎 | 後 7 碼 | NT$ 40,000 | |
| 三獎 | 後 6 碼 | NT$ 10,000 | |
| 四獎 | 後 5 碼 | NT$ 4,000 | |
| 五獎 | 後 4 碼 | NT$ 1,000 | |
| 六獎 | 後 3 碼 | NT$ 200 | |

> 每局約 90% 的發票為中獎發票；連勝時高獎項機率顯著提升。

---

## ✨ 特色功能

### 視覺 & 動畫
- **飛卡動畫** — 滑動後卡片飛出，下一張無縫補入，延遲僅 30ms
- **大獎慶祝特效** — 頭獎／特獎／特別獎觸發全螢幕閃光 + 36 粒粒子爆炸 + Banner 滑入
- **連勝邊框光暈** — 螢幕四邊隨連勝段位變色（金 → 橘 → 深橘 → 紅）
- **拖曳即時回饋** — 右滑出現綠色「中獎！」、左滑出現紅色「未中獎」半透明覆蓋
- **強制暗色主題** — 深藍黑背景，統一 Brand 色系

### 音效 & 觸覺
- **100% 程式合成音效** — AVAudioEngine 正弦波合成，無需任何音訊資源檔
- **分層音效系統** — 每種事件（滑動 / 答對 / 答錯 / 連勝里程碑 / 大獎 / 扣血 / 倒數）有專屬頻率組合與旋律
- **精細 Haptics** — 30+ 種觸覺模式，大獎最多 3 次重擊，扣血遞減強度震動

### 排行榜 & 社群
- **App 內原生排行榜** — 不需跳出至 Game Center，直接在 App 內瀏覽 Top 20 全球名次與玩家頭像
- **結果頁名次對比** — 顯示自己排名及上下一名玩家，即時對比
- **三種獨立排行榜** — 一般 / 每日挑戰 / 無限模式各自計算

### 教學 & 設定
- **模式專屬教學** — 首次進入每種模式自動彈出，設定頁可隨時重看
- **音效開關** — 單一開關控制全局音效
- **Game Center 快捷登入** — 設定頁顯示認證狀態，未登入時一鍵跳轉

### IAP & 評分
- **請喝咖啡** — StoreKit 2 非消耗型一次性支持（含 Restore 功能）
- **評分提示** — 累計玩滿 5 局後出現 App Store 評分請求（每個 App 生命週期一次）

---

## 🏗 專案架構

```
InvoiceSwipeGame/
├── InvoiceSwipeGameApp.swift       # App 進入點
├── ContentView.swift               # 根導覽（相位切換）
├── ColorExtensions.swift           # 全域命名色常數
├── Extensions.swift                # 通用擴充
├── Models/
│   ├── Invoice.swift               # 發票資料結構
│   ├── GameMode.swift              # 遊戲模式列舉
│   ├── WinTier.swift               # 中獎級別（特別獎～六獎）
│   └── PrizeNumbers.swift          # 本期獎號
├── ViewModels/
│   ├── GameViewModel.swift         # 核心遊戲狀態與邏輯（@MainActor）
│   └── LeaderboardViewModel.swift  # 排行榜資料擷取與頭像非同步載入
├── Views/
│   ├── StartView.swift             # 模式選擇首頁
│   ├── GameView.swift              # 主遊戲畫面（HUD / 卡堆 / 操作列）
│   ├── ResultView.swift            # 結果統計與排名對比
│   ├── LeaderboardView.swift       # App 內原生排行榜（Tab 切換）
│   ├── InvoiceCardView.swift       # 發票卡片元件（含拖曳覆蓋層）
│   ├── CountdownView.swift         # 3–2–1–GO! 倒數動畫
│   ├── BigWinOverlayView.swift     # 大獎慶祝閃光 + 粒子
│   ├── ConfettiView.swift          # 紙屑粒子特效
│   ├── TutorialView.swift          # 模式專屬教學說明
│   └── SettingsView.swift          # 設定、IAP 與 Game Center
└── Services/
    ├── SoundManager.swift           # AVAudioEngine 合成音效引擎
    ├── HapticsManager.swift         # UIKit Haptics 觸覺回饋
    ├── PrizeChecker.swift           # 對獎邏輯與發票生成
    ├── SeededRNG.swift              # Mulberry32 可復現亂數
    ├── DailyChallengeManager.swift  # 每日挑戰次數與最佳紀錄
    ├── GameCenterManager.swift      # GKLeaderboard 排行榜與認證
    └── StoreKitManager.swift        # StoreKit 2 應用程式內購買
```

---

## 🔧 技術棧

| 技術 | 用途 |
|------|------|
| **SwiftUI** | 全畫面 UI 框架，強制暗色主題 |
| **Combine** | Timer、狀態響應式管理 |
| **AVAudioEngine** | 程式合成音效（正弦波，44.1 kHz） |
| **GameKit** | Game Center 排行榜、認證、頭像 |
| **StoreKit 2** | 非消耗型 IAP，async/await 交易驗證 |
| **UserDefaults** | 音效設定、教學狀態、每日挑戰資料 |

---

## 🚀 建置方式

1. **環境需求**
   - Xcode 15+
   - iOS 16.0+ 裝置或模擬器

2. **Clone 專案**
   ```bash
   git clone https://github.com/Neroal/invoice-swipe-game-ios.git
   cd invoice-swipe-game-ios
   ```

3. **開啟 Xcode**
   ```bash
   open InvoiceSwipeGame.xcodeproj
   ```

4. **選擇目標裝置，按下 ▶ 執行**

> **注意**：Game Center 功能需要真實裝置與有效 Apple ID；IAP 測試請使用 StoreKit 設定檔（`發票對對碰.storekit`）。

---

## 📋 排行榜 ID

若要在 App Store Connect 設定 Game Center，請建立以下三個排行榜：

| Leaderboard ID | 說明 | 分數單位 |
|----------------|------|----------|
| `invoice.normal.score` | 一般模式 | 30 秒內總獎金（NT$） |
| `invoice.daily.score.v2` | 每日挑戰 | 獎金 × 正確率（每日重置） |
| `invoice.endless.streak` | 無限模式 | 最高連勝數 |

---

## 🔒 隱私權政策

本應用程式不收集任何個人資料。
詳細說明請參閱：[隱私權政策](https://neroal.github.io/invoice-swipe-game-ios/)

---

## 📄 授權

本專案採用 [MIT License](LICENSE) 授權。

---

<p align="center">Made with ❤️ by <a href="https://github.com/Neroal">Neroal</a></p>
