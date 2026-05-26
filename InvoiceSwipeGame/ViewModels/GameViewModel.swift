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
    @Published var timeLeft:     Int = 30
    @Published var totalCount:   Int = 0
    @Published var correctCount: Int = 0
    @Published var scoreBonus:   Int = 0   // 計時模式大獎額外加分累計
    // Endless
    @Published var lives:         Int = 3
    @Published var currentStreak: Int = 0
    @Published var bestStreak:    Int = 0

    // MARK: – Game over flag (prevents swipes after lives run out)
    @Published var isGameOver = false

    // MARK: – Card drag
    @Published var dragOffset: CGSize = .zero
    @Published var isAnimating = false

    // MARK: – Flying card overlay (decoupled from input lock)
    @Published var flyingCard: Invoice?       = nil
    @Published var flyingDir:  SwipeDirection? = nil
    @Published var flyingStartOffset: CGSize  = .zero

    // MARK: – Feedback
    @Published var feedbackText     = ""
    @Published var feedbackCorrect  = true
    @Published var showFeedback     = false
    @Published var miniBadgeText    = ""
    @Published var miniBadgeTier: WinTier? = nil
    @Published var showMiniBadge    = false

    // MARK: – Big-win overlay
    @Published var showBigWin   = false
    @Published var bigWinTier: WinTier? = nil

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
    let sound              = SoundManager()
    let haptics            = HapticsManager()
    private let daily      = DailyChallengeManager()

    // MARK: – Mode selection
    func selectMode(_ mode: GameMode) {
        if mode == .daily, !daily.canPlay { return }
        currentMode = mode
        if !UserDefaults.standard.bool(forKey: "tutorial_seen") {
            showTutorial = true
        } else {
            beginGame()
        }
    }

    func dismissTutorial() {
        UserDefaults.standard.set(true, forKey: "tutorial_seen")
        showTutorial = false
        beginGame()
    }

    // MARK: – Game flow
    func beginGame() {
        // Reset state
        timeLeft      = 30
        totalCount    = 0
        correctCount  = 0
        scoreBonus    = 0
        lives         = 3
        currentStreak = 0
        bestStreak    = 0
        dragOffset    = .zero
        isAnimating   = false
        isNewDailyRecord  = false
        isGameOver        = false
        showFeedback      = false
        showMiniBadge     = false
        showBigWin        = false
        flyingCard        = nil
        flyingDir         = nil
        flyingStartOffset = .zero

        rng = currentMode == .daily
            ? SeededRNG(seed: SeededRNG.dailySeed())
            : SeededRNG(seed: UInt32.random(in: 1..<UInt32.max))

        prizes = PrizeChecker.generatePrizeNumbers(rng: &rng)
        cards  = (0..<8).map { _ in PrizeChecker.generateInvoice(prizes: prizes, rng: &rng) }

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
                    self.endGame()
                }
            }
    }

    // MARK: – Swipe processing
    func processSwipe(_ dir: SwipeDirection) {
        guard !isAnimating, !cards.isEmpty, phase == .playing, !isGameOver else { return }
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

        totalCount += 1
        if correct {
            correctCount += 1
            if currentMode == .endless {
                currentStreak += 1
                if currentStreak > bestStreak { bestStreak = currentStreak }
            }
        } else {
            if currentMode == .endless {
                currentStreak = 0
                handleLifeLost()
            }
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
                    cards.append(PrizeChecker.generateInvoice(prizes: prizes, rng: &rng))
                }
                dragOffset  = .zero
                isAnimating = false
            }
        }

        // Stage 2（340ms）：清除 flying overlay（卡片已飛離螢幕）
        Task {
            try? await Task.sleep(nanoseconds: 340_000_000)
            flyingCard        = nil
            flyingDir         = nil
            flyingStartOffset = .zero
        }
    }

    private func handleLifeLost() {
        lives -= 1
        sound.playLifeLost()
        haptics.lifeLost()
        if lives <= 0 {
            isGameOver = true
            Task {
                try? await Task.sleep(nanoseconds: 420_000_000)
                endGame()
            }
        }
    }

    // MARK: – Feedback
    private func deliverFeedback(correct: Bool, card: Invoice) {
        if correct, let tier = card.winTier, tier.isBigWin {
            if currentMode.hasTimer {
                // 計時模式：強化 mini badge + 加分，不打斷遊戲流程
                triggerBigWinMini(tier)
            } else {
                // 無限模式：保留全螢幕 overlay
                triggerBigWin(tier)
            }
            return
        }
        if correct, let tier = card.winTier {
            // Small win badge
            scoreBonus += tier.bonusPoints
            sound.playCoin()
            haptics.coin()
            miniBadgeTier = tier
            miniBadgeText = "\(tier.rawValue)  \(tier.scoreText)"
            withAnimation(.spring(dampingFraction: 0.6)) { showMiniBadge = true }
            Task {
                try? await Task.sleep(nanoseconds: 900_000_000)
                withAnimation { showMiniBadge = false }
            }
        } else {
            if correct {
                sound.playCorrect()
                haptics.correct()
            } else {
                sound.playWrong()
                haptics.wrong()
            }
        }

        feedbackText    = correct
            ? (card.isWinner ? "\(card.winTier?.rawValue ?? "中獎")！" : "✓ 正確")
            : (card.isWinner ? "✗ 漏了！" : "✗ 答錯")
        feedbackCorrect = correct

        withAnimation(.spring()) { showFeedback = true }
        Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            withAnimation { showFeedback = false }
        }
    }

    /// 計時模式大獎處理：強化 mini badge + 加分，不蓋住畫面
    private func triggerBigWinMini(_ tier: WinTier) {
        scoreBonus += tier.bonusPoints
        switch tier {
        case .special: sound.playSpecialPrize()
        case .grand:   sound.playGrandPrize()
        case .first:   sound.playFirstPrize()
        default: break
        }
        haptics.bigWin(tier: tier)
        miniBadgeTier = tier
        miniBadgeText = "★ \(tier.rawValue)  \(tier.scoreText)"
        withAnimation(.spring(dampingFraction: 0.6)) { showMiniBadge = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            withAnimation { showMiniBadge = false }
        }
    }

    private func triggerBigWin(_ tier: WinTier) {
        bigWinTier = tier
        withAnimation(.spring(dampingFraction: 0.65)) { showBigWin = true }
        haptics.bigWin(tier: tier)
        switch tier {
        case .special: sound.playSpecialPrize()
        case .grand:   sound.playGrandPrize()
        case .first:   sound.playFirstPrize()
        default: break
        }
        let dur: UInt64 = tier == .special ? 1_500_000_000
                        : tier == .grand   ? 1_200_000_000 : 900_000_000
        Task {
            try? await Task.sleep(nanoseconds: dur)
            withAnimation { showBigWin = false }
        }
    }

    // MARK: – End game
    func endGame() {
        timerSub?.cancel()
        // 無限模式由 playLifeLost() 已給過音效，不重複播放「時間到」
        if currentMode.hasTimer {
            sound.playTimeUp()
            haptics.timeUp()
        }

        if currentMode == .daily {
            daily.recordAttempt()
            isNewDailyRecord = daily.tryUpdateBest(score)
        }
        dailyBestScore = daily.bestScore()
        phase = .result

        // 上傳 Game Center 分數
        submitGameCenterScore()
    }

    private func submitGameCenterScore() {
        let gc = GameCenterManager.shared
        switch currentMode {
        case .normal:
            gc.submitScore(score,      to: .normal)
        case .daily:
            gc.submitScore(score,      to: .daily)
        case .endless:
            gc.submitScore(bestStreak * 1000 + totalCount, to: .endless)
        }
    }

    func replayCurrentMode() { beginGame() }

    func goHome() {
        timerSub?.cancel()
        countdownTask?.cancel()
        showCountdown     = false
        showFeedback      = false
        showMiniBadge     = false
        showBigWin        = false
        flyingCard        = nil
        flyingDir         = nil
        flyingStartOffset = .zero
        phase = .start
    }

    // MARK: – Computed helpers
    var dailyBestText: String       { daily.bestDisplayText    }
    var dailyAttemptsText: String   { daily.attemptsDisplayText }
    var dailyRemainingAttempts: Int { daily.remainingAttempts  }
    var canPlayDaily: Bool          { daily.canPlay            }

    var wrongCount: Int { totalCount - correctCount }

    /// 加權分數：答對 ×2，答錯 ×3，大獎額外加分（下限 0）
    var score: Int { max(0, correctCount * 2 - wrongCount * 3 + scoreBonus) }

    var accuracy: Int {
        totalCount > 0 ? Int(Double(correctCount) / Double(totalCount) * 100) : 0
    }

    var currentPeriodLabel: String {
        let d = Date()
        let c = Calendar.current
        let roc = c.component(.year, from: d) - 1911
        let m   = c.component(.month, from: d)
        let ps  = m % 2 == 0 ? m - 1 : m
        return "\(roc)年 \(ps)–\(ps + 1)月 中獎號碼"
    }
}
