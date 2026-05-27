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
  <img src="https://img.shields.io/badge/version-1.0.0-lightgrey" />
  <img src="https://img.shields.io/badge/license-MIT-informational" />
</p>

---

## 🎮 遊戲介紹

**發票對對碰**是一款以台灣統一發票對獎為主題的 iOS 休閒遊戲。畫面上會出現一張張模擬發票，玩家必須快速判斷該張發票是否中獎——向右滑「中獎」、向左滑「未中獎」——在時間壓力或有限生命中衝高分數。

---

## 🕹️ 遊戲模式

| 模式 | 說明 | 計分方式 |
|------|------|----------|
| **一般模式** ⏱ | 30 秒限時，看誰分數最高 | 答對 +2、答錯 -3、中獎加成最高 +10 |
| **每日挑戰** 📅 | 每日限 3 次、全球同一套題目 | 同一般模式，有每日最佳紀錄 |
| **無限模式** ♾️ | 3 條命，錯一次扣一條命 | 連勝 × 1000 + 總張數 |

---

## ✨ 特色功能

- **即時滑動手勢** — 左右滑動或點擊按鈕進行判斷，流暢的飛卡動畫
- **七級中獎判定** — 從六獎（後 3 碼）到特別獎（完整 8 碼）精準核對
- **大獎慶祝動畫** — 頭獎、特獎、特別獎觸發全螢幕彩帶特效與音效
- **100% 合成音效** — 使用 AVAudioEngine 程式合成，無需音訊資源檔
- **觸覺回饋** — 根據結果提供對應強度的 Haptics 震動
- **Game Center 排行榜** — 三種模式各有獨立全球排行榜
- **每日挑戰同步** — 以日期作為 RNG 種子，確保全球玩家同一道題
- **請喝咖啡 IAP** — 非消耗型 StoreKit 2 一次性支持

---

## 🏗 專案架構

```
InvoiceSwipeGame/
├── Models/
│   ├── Invoice.swift           # 發票資料結構
│   ├── GameMode.swift          # 遊戲模式列舉
│   ├── WinTier.swift           # 中獎級別（特別獎～六獎）
│   └── PrizeNumbers.swift      # 本期獎號
├── ViewModels/
│   └── GameViewModel.swift     # 核心遊戲狀態與邏輯
├── Views/
│   ├── ContentView.swift       # 根導覽
│   ├── StartView.swift         # 模式選擇
│   ├── GameView.swift          # 主遊戲畫面
│   ├── ResultView.swift        # 結果統計
│   ├── InvoiceCardView.swift   # 發票卡片元件
│   ├── CountdownView.swift     # 3-2-1-GO! 倒數
│   ├── BigWinOverlayView.swift # 大獎慶祝覆蓋層
│   ├── ConfettiView.swift      # 紙屑粒子特效
│   ├── TutorialView.swift      # 教學說明
│   └── SettingsView.swift      # 設定與 IAP
└── Services/
    ├── SoundManager.swift           # 合成音效引擎
    ├── HapticsManager.swift         # 觸覺回饋
    ├── PrizeChecker.swift           # 對獎邏輯與發票生成
    ├── SeededRNG.swift              # 可復現亂數（每日挑戰用）
    ├── DailyChallengeManager.swift  # 每日挑戰次數與最佳紀錄
    ├── GameCenterManager.swift      # 排行榜與認證
    └── StoreKitManager.swift        # 應用程式內購買
```

---

## 🔧 技術棧

| 技術 | 用途 |
|------|------|
| **SwiftUI** | 全畫面 UI 框架 |
| **Combine** | 響應式狀態管理 |
| **AVAudioEngine** | 程式合成音效（正弦/方波/鋸齒波） |
| **GameKit** | Game Center 排行榜與認證 |
| **StoreKit 2** | 應用程式內購買 |
| **UserDefaults** | 輕量資料持久化 |

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

| Leaderboard ID | 說明 | 分數 |
|----------------|------|------|
| `invoice.normal.score` | 一般模式 | 30 秒內得分 |
| `invoice.daily.score` | 每日挑戰 | 每日最佳得分 |
| `invoice.endless.streak` | 無限模式 | 連勝 × 1000 + 總張數 |

---

## 🔒 隱私權政策

本應用程式不收集任何個人資料。
詳細說明請參閱：[隱私權政策](https://neroal.github.io/invoice-swipe-game-ios/)

---

## 📄 授權

本專案採用 [MIT License](LICENSE) 授權。

---

<p align="center">Made with ❤️ by <a href="https://github.com/Neroal">Neroal</a></p>
