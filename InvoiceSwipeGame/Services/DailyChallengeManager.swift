import Foundation

struct DailyChallengeManager {

    static let maxAttempts = 3

    // MARK: – Date key (共用，隔天自動換 key)

    private var dateString: String {
        let c = Calendar.current
        let d = Date()
        let y   = c.component(.year,  from: d)
        let m   = c.component(.month, from: d)
        let day = c.component(.day,   from: d)
        return String(format: "%04d%02d%02d", y, m, day)
    }

    private var storageKey:  String { "daily_best_\(dateString)"     }
    private var attemptsKey: String { "daily_attempts_\(dateString)" }

    // MARK: – Best score

    func bestScore() -> Int {
        UserDefaults.standard.integer(forKey: storageKey)
    }

    @discardableResult
    func tryUpdateBest(_ score: Int) -> Bool {
        guard score > bestScore() else { return false }
        UserDefaults.standard.set(score, forKey: storageKey)
        return true
    }

    var bestDisplayText: String {
        let b = bestScore()
        guard b > 0 else { return "" }
        let f = NumberFormatter()
        f.numberStyle = .decimal
        let formatted = f.string(from: NSNumber(value: b)) ?? "\(b)"
        return "今日最高：NT$ \(formatted)"
    }

    // MARK: – Attempts

    func attemptsUsed() -> Int {
        UserDefaults.standard.integer(forKey: attemptsKey)
    }

    var remainingAttempts: Int {
        max(0, Self.maxAttempts - attemptsUsed())
    }

    var canPlay: Bool { remainingAttempts > 0 }

    func recordAttempt() {
        UserDefaults.standard.set(attemptsUsed() + 1, forKey: attemptsKey)
    }

    var attemptsDisplayText: String {
        remainingAttempts > 0
            ? "今日剩餘 \(remainingAttempts) 次"
            : "今日挑戰已結束"
    }
}
