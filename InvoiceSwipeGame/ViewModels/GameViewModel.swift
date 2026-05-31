import SwiftUI
import Combine
import GameKit

enum GamePhase { case start, countdown, playing, result }
enum SwipeDirection { case left, right }

@MainActor
final class GameViewModel: ObservableObject {

    // MARK: – Navigation
    @Published var phase: GamePhase = .start
    @Published var showTutorial  = false
    @Published var showSettings  = false

    // MARK: – Mode
    @Published var currentMode: GameMode = .normal

    // MARK: – Game data
    @Published var prizes: PrizeNumbers = .placeholder
    @Published var cards:  [Invoice] = []

    // MARK: – HUD
    @Published var timeLeft:          Int = 30
    @Published var totalCount:        Int = 0
    @Published var correctCount:      Int = 0
    @Published var totalPrizeAmount:  Int = 0   // 本局中獎總金額（一般 / 每日挑戰）
    // Endless
    @Published var lives:         Int = 3
    @Published var currentStreak: Int = 0
    @Published var bestStreak:    Int = 0

    // MARK: – Burst window（一般 / 每日挑戰）：每局隨機在第 N–N+2 張強制出現三獎以上
    private var burstStartIndex: Int = 0
    private var cardIndex:       Int = 0   // 本局已發牌數（用於判斷是否在爆發視窗內）

    // MARK: – Game over flag (prevents swipes after lives run out)
    @Published var isGameOver = false

    // MARK: – Burn timer (Endless only)
    @Published var burnTimeLeft:  Double = 8.0
    @Published var burnTimerFull: Double = 8.0
    private var burnTimerSub: AnyCancellable?

    // MARK: – Card drag
    @Published var dragOffset: CGSize = .zero
    @Published var isAnimating = false

    // MARK: – Flying card overlay (decoupled from input lock)
    @Published var flyingCard: Invoice?       = nil
    @Published var flyingDir:  SwipeDirection? = nil
    @Published var flyingStartOffset: CGSize  = .zero
    /// 追蹤目前飛行中的卡片 ID，Stage 2 Task 用於確認是否仍為同一張卡
    private var flyingCardID: UUID?            = nil

    // MARK: – Feedback
    @Published var feedbackText     = ""
    @Published var feedbackCorrect  = true
    var feedbackColor: Color {
        guard feedbackCorrect else { return Color.errorRed }
        if currentStreak >= 3 { return Self.comboColor(for: currentStreak) }
        return Color.successGreen
    }
    @Published var showFeedback     = false

    // MARK: – Big-win (non-blocking banner + flash)
    @Published var showBigWin   = false
    @Published var bigWinFlash  = false
    @Published var bigWinTier: WinTier? = nil
    @Published var bigWinID:    Int = 0   // 每次中獎自增，強制 SwiftUI re-insert banner
    private var bigWinTask: Task<Void, Never>? = nil

    // MARK: – Countdown
    @Published var countdownValue = 3
    @Published var countdownIsGo  = false
    @Published var showCountdown  = false

    // MARK: – Result
    @Published var isNewDailyRecord = false
    @Published var dailyBestScore   = 0

    // MARK: – Private
    private var rng        = SeededRNG(seed: 0)
    private var timerSub:  AnyCancellable?
    private var countdownTask: Task<Void, Never>?
    private var lifeLostTask:  Task<Void, Never>?
    let sound              = SoundManager()
    let haptics            = HapticsManager()
    private let daily      = DailyChallengeManager()

    // MARK: – Review Request
    private let gamesPlayedKey    = "total_games_played"
    private let reviewRequestedKey = "review_requested"
    private let reviewThreshold   = 5

    /// 累積遊玩局數（跨模式）
    var totalGamesPlayed: Int {
        UserDefaults.standard.integer(forKey: gamesPlayedKey)
    }

    /// 是否達到評分請求門檻且尚未觸發過
    var hasReachedReviewThreshold: Bool {
        let alreadyRequested = UserDefaults.standard.bool(forKey: reviewRequestedKey)
        return totalGamesPlayed >= reviewThreshold && !alreadyRequested
    }

    /// 標記已觸發評分請求，之後不再觸發
    func markReviewRequested() {
        UserDefaults.standard.set(true, forKey: reviewRequestedKey)
    }

    private func incrementGamesPlayed() {
        let newCount = totalGamesPlayed + 1
        UserDefaults.standard.set(newCount, forKey: gamesPlayedKey)
    }

    // MARK: – Mode selection
    func selectMode(_ mode: GameMode) {
        if mode == .daily, !daily.canPlay { return }
        currentMode = mode
        if !UserDefaults.standard.bool(forKey: "tutorial_seen_\(mode.rawValue)") {
            showTutorial = true
        } else {
            beginGame()
        }
    }

    func dismissTutorial() {
        UserDefaults.standard.set(true, forKey: "tutorial_seen_\(currentMode.rawValue)")
        showTutorial = false
        beginGame()
    }

    // MARK: – Game flow
    func beginGame() {
        // Cancel any pending delayed endGame from the previous round
        lifeLostTask?.cancel()
        lifeLostTask = nil

        // Reset state
        timeLeft          = 30
        totalCount        = 0
        correctCount      = 0
        totalPrizeAmount  = 0
        lives          = 3
        currentStreak  = 0
        bestStreak     = 0
        cardIndex      = 0
        dragOffset    = .zero
        isAnimating   = false
        isNewDailyRecord  = false
        isGameOver        = false
        showFeedback      = false
        showBigWin        = false
        bigWinFlash       = false
        bigWinID          = 0
        flyingCard        = nil
        flyingDir         = nil
        flyingStartOffset = .zero
        flyingCardID      = nil

        stopBurnTimer()

        rng = currentMode == .daily
            ? SeededRNG(seed: SeededRNG.dailySeed())
            : SeededRNG(seed: UInt32.random(in: 1..<UInt32.max))

        prizes = PrizeChecker.generatePrizeNumbers(rng: &rng)
        // 爆發視窗：無限模式不啟用，其他模式在第 5–15 張觸發，連續 3 張
        burstStartIndex = currentMode == .endless ? Int.max : 5 + Int(rng.next() * 11)
        cards  = (0..<8).map { _ in nextInvoice() }

        phase = .countdown
        runCountdown()
    }

    private func runCountdown() {
        showCountdown = true
        countdownTask?.cancel()
        countdownTask = Task {
            for n in stride(from: 3, through: 1, by: -1) {
                guard !Task.isCancelled else { return }
                countdownValue = n
                countdownIsGo  = false
                sound.playBeep(heavy: n == 3)
                haptics.beep(heavy: n == 3)
                try? await Task.sleep(nanoseconds: 900_000_000)
            }
            guard !Task.isCancelled else { return }
            countdownIsGo = true
            sound.playBeep(heavy: true)
            haptics.beep(heavy: true)
            try? await Task.sleep(nanoseconds: 600_000_000)
            guard !Task.isCancelled else { return }
            showCountdown = false
            phase = .playing
            if currentMode.hasTimer { startTimer() }
            if currentMode == .endless { startBurnTimer() }
        }
    }

    private func startTimer() {
        timerSub?.cancel()
        timerSub = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.timeLeft -= 1
                if self.timeLeft <= 5 { self.sound.playTick(); self.haptics.tick() }
                if self.timeLeft <= 0 {
                    self.timerSub?.cancel()
                    self.timerSub = nil
                    self.endGame()
                }
            }
    }

    // MARK: – Invoice generation
    private func nextInvoice() -> Invoice {
        let isBurst = (cardIndex >= burstStartIndex && cardIndex < burstStartIndex + 3)
        let invoice = PrizeChecker.generateInvoice(prizes: prizes, rng: &rng, mode: currentMode, isBurst: isBurst)
        cardIndex += 1
        return invoice
    }

    // MARK: – Swipe processing
    func processSwipe(_ dir: SwipeDirection) {
        guard !isAnimating, !cards.isEmpty, phase == .playing, !isGameOver else { return }
        if currentMode == .endless { burnTimerSub?.cancel(); burnTimerSub = nil }
        isAnimating = true
        sound.playSwipe()
        haptics.swipe()

        let card      = cards[0]
        let playerWin = (dir == .right)
        let correct   = (playerWin == card.isWinner)

        // 啟動 flying overlay，接管飛出動畫
        flyingStartOffset = dragOffset
        flyingCard        = card
        flyingDir         = dir
        flyingCardID      = card.id

        totalCount += 1
        if correct {
            correctCount += 1
            currentStreak += 1
            if currentStreak > bestStreak { bestStreak = currentStreak }
            let milestones = [5, 10, 20]
            if milestones.contains(currentStreak) || (currentStreak > 20 && currentStreak % 10 == 0) {
                sound.playCombo(streak: currentStreak)
                haptics.comboMilestone(streak: currentStreak)
            }
        } else {
            if currentStreak >= 3 { haptics.comboBreak() }
            currentStreak = 0
            if currentMode == .endless { handleLifeLost() }
        }

        deliverFeedback(correct: correct, card: card)

        // Stage 1（30ms）：移除卡片、補牌、解鎖輸入
        // 只留一幀讓 FlyingCardView 先出現，接著立刻解鎖
        // 用 withTransaction 明確禁用動畫，避免繼承 deliverFeedback 的 withAnimation context
        Task {
            try? await Task.sleep(nanoseconds: 30_000_000)
            var t = Transaction(animation: nil)
            t.disablesAnimations = true
            withTransaction(t) {
                cards.removeFirst()
                while cards.count < 6 {
                    cards.append(nextInvoice())
                }
                dragOffset  = .zero
                isAnimating = false
            }
            if currentMode == .endless && !isGameOver { startBurnTimer() }
        }

        // Stage 2（340ms）：清除 flying overlay（卡片已飛離螢幕）
        // 比對 card.id 確保不會清除下一張牌的飛行動畫
        let swipedCardID = card.id
        Task {
            try? await Task.sleep(nanoseconds: 340_000_000)
            guard flyingCardID == swipedCardID else { return }
            flyingCard        = nil
            flyingDir         = nil
            flyingStartOffset = .zero
            flyingCardID      = nil
        }
    }

    private func handleLifeLost() {
        lives -= 1
        sound.playLifeLost()
        haptics.lifeLost()
        if lives <= 0 {
            isGameOver = true
            stopBurnTimer()
            lifeLostTask = Task {
                try? await Task.sleep(nanoseconds: 420_000_000)
                guard !Task.isCancelled else { return }
                endGame()
            }
        }
    }

    // MARK: – Burn timer (Endless only)

    private func burnDuration(streak: Int) -> Double {
        switch streak {
        case 0..<5:   return 8.0
        case 5..<10:  return 6.0
        case 10..<20: return 4.0
        default:      return 3.0
        }
    }

    private func startBurnTimer() {
        guard currentMode == .endless, phase == .playing, !isGameOver else { return }
        burnTimerSub?.cancel()
        let duration = burnDuration(streak: currentStreak)
        burnTimerFull = duration
        burnTimeLeft  = duration
        burnTimerSub = Timer.publish(every: 0.05, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.phase == .playing, !self.isGameOver else { return }
                self.burnTimeLeft = max(0, self.burnTimeLeft - 0.05)
                if self.burnTimeLeft <= 0 {
                    self.burnTimerSub?.cancel()
                    self.burnTimerSub = nil
                    self.handleBurnTimeout()
                }
            }
    }

    private func stopBurnTimer() {
        burnTimerSub?.cancel()
        burnTimerSub = nil
        burnTimeLeft  = 8.0
        burnTimerFull = 8.0
    }

    private func handleBurnTimeout() {
        guard !cards.isEmpty, phase == .playing, !isGameOver else { return }

        sound.playWrong()
        haptics.wrong()
        if currentStreak >= 3 { haptics.comboBreak() }
        currentStreak = 0
        totalCount += 1

        feedbackText    = "⏰ 超時！"
        feedbackCorrect = false
        withAnimation(.spring()) { showFeedback = true }
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation { showFeedback = false }
        }

        handleLifeLost()

        var t = Transaction(animation: nil)
        t.disablesAnimations = true
        withTransaction(t) {
            if !cards.isEmpty { cards.removeFirst() }
            while cards.count < 6 {
                cards.append(nextInvoice())
            }
        }

        if !isGameOver { startBurnTimer() }
    }

    // MARK: – Feedback
    private func deliverFeedback(correct: Bool, card: Invoice) {
        if correct, let tier = card.winTier {
            triggerBigWinEffect(tier)   // 聲音在此處理，不重複播放
        } else if correct {
            sound.playCorrect()
            haptics.correct()
        } else {
            sound.playWrong()
            haptics.wrong()
        }

        // streak ≥ 3 → 顯示 COMBO ×N（對應顏色），全模式
        if correct && currentStreak >= 3 {
            feedbackText    = "COMBO ×\(currentStreak)"
            feedbackCorrect = true
            withAnimation(.spring()) { showFeedback = true }
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation { showFeedback = false }
            }
            return
        }

        feedbackText    = correct ? "✓ 正確" : (card.isWinner ? "✗ 漏了！" : "✗ 答錯")
        feedbackCorrect = correct
        withAnimation(.spring()) { showFeedback = true }
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation { showFeedback = false }
        }
    }

    static func comboColor(for streak: Int) -> Color {
        switch streak {
        case 3..<5:   return Color.gameGold   // 進入 combo 但仍在 phase 1
        case 5..<10:  return Color(hex: "ff6600")   // phase 2
        case 10..<20: return Color.comboDeepOrange   // phase 3
        default:      return Color.comboBrightRed   // phase 4 (20+)
        }
    }

    /// 非阻斷式大獎演出：螢幕閃光 + 粒子爆炸 + 邊緣衝入 banner，全模式統一
    private func triggerBigWinEffect(_ tier: WinTier) {
        // 取消前一個 hide task，避免舊 task 提早關掉新 banner
        bigWinTask?.cancel()
        bigWinTask = nil

        totalPrizeAmount += tier.prizeAmount
        switch tier {
        case .special: sound.playSpecialPrize()
        case .grand:   sound.playGrandPrize()
        case .first:   sound.playFirstPrize()
        default:       sound.playCoin()   // 二～六獎
        }
        if tier.isBigWin { haptics.bigWin(tier: tier) } else { haptics.coin() }

        // 閃光只給特別獎/特獎/頭獎
        if tier.isBigWin {
            withAnimation(.easeOut(duration: 0.05)) { bigWinFlash = true }
            Task {
                try? await Task.sleep(nanoseconds: 130_000_000)
                withAnimation(.easeOut(duration: 0.18)) { bigWinFlash = false }
            }
        }
        // bigWinID 自增 → SwiftUI 視為全新 view → 重新執行 slide-in transition
        withAnimation(.spring(dampingFraction: 0.65)) {
            bigWinTier = tier
            bigWinID  += 1
            showBigWin = true
        }
        let dur: UInt64
        switch tier {
        case .special: dur = 1_400_000_000
        case .grand:   dur = 1_100_000_000
        case .first:   dur =   900_000_000
        default:       dur =   650_000_000   // 二～六獎
        }
        bigWinTask = Task {
            try? await Task.sleep(nanoseconds: dur)
            guard !Task.isCancelled else { return }
            withAnimation(.easeIn(duration: 0.25)) { showBigWin = false }
        }
    }

    // MARK: – End game
    func endGame() {
        // 防重入：只有遊戲進行中或倒數中才允許結束
        guard phase == .playing || phase == .countdown else { return }

        timerSub?.cancel()
        timerSub = nil
        stopBurnTimer()
        // 無限模式由 playLifeLost() 已給過音效，不重複播放「時間到」
        if currentMode.hasTimer {
            sound.playTimeUp()
            haptics.timeUp()
        }

        if currentMode == .daily {
            daily.recordAttempt()
            isNewDailyRecord = daily.tryUpdateBest(dailyFinalScore)
        }
        dailyBestScore = daily.bestScore()

        // 累積局數 +1（任一模式皆計算）
        incrementGamesPlayed()

        phase = .result

        // 上傳 Game Center 分數
        submitGameCenterScore()
    }

    private func submitGameCenterScore() {
        let gc = GameCenterManager.shared
        switch currentMode {
        case .normal:
            gc.submitScore(totalPrizeAmount, to: .normal)
        case .daily:
            gc.submitScore(dailyFinalScore, to: .daily)
        case .endless:
            gc.submitScore(bestStreak, to: .endless)
        }
    }

    func replayCurrentMode() { beginGame() }

    func goHome() {
        timerSub?.cancel()
        timerSub = nil
        stopBurnTimer()
        countdownTask?.cancel()
        countdownTask = nil
        lifeLostTask?.cancel()
        lifeLostTask = nil
        showCountdown     = false
        showFeedback      = false
        showBigWin        = false
        bigWinFlash       = false
        flyingCard        = nil
        flyingDir         = nil
        flyingStartOffset = .zero
        flyingCardID      = nil
        phase = .start
    }

    // MARK: – Computed helpers
    var dailyBestText: String       { daily.bestDisplayText    }
    var dailyAttemptsText: String   { daily.attemptsDisplayText }
    var dailyRemainingAttempts: Int { daily.remainingAttempts  }
    var canPlayDaily: Bool          { daily.canPlay            }

    var wrongCount: Int { totalCount - correctCount }

    var accuracy: Int {
        totalCount > 0 ? Int(Double(correctCount) / Double(totalCount) * 100) : 0
    }

    var dailyFinalScore: Int {
        totalPrizeAmount > 0 ? Int(Double(totalPrizeAmount) * Double(accuracy) / 100.0) : 0
    }

    var dailyFinalScoreString: String { Self.formatPrize(dailyFinalScore) }

    var totalPrizeAmountString: String { Self.formatPrize(totalPrizeAmount) }
    var dailyBestPrizeString:   String { Self.formatPrize(dailyBestScore)   }

    private static let decimalFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    /// HUD 用縮寫：≥ 1萬 改用萬單位，結果頁仍用完整格式
    var hudPrizeString: String {
        let f = Self.decimalFormatter
        if totalPrizeAmount >= 10_000 {
            let wan = totalPrizeAmount / 10_000
            return "NT$ \(f.string(from: NSNumber(value: wan)) ?? "\(wan)")萬"
        }
        return "NT$ \(f.string(from: NSNumber(value: totalPrizeAmount)) ?? "\(totalPrizeAmount)")"
    }

    static func formatPrize(_ amount: Int) -> String {
        let formatted = decimalFormatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return "NT$ \(formatted)"
    }
}
