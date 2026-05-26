import Foundation

struct DailyChallengeManager {

    private var storageKey: String {
        let c = Calendar.current
        let d = Date()
        let y   = c.component(.year,  from: d)
        let m   = c.component(.month, from: d)
        let day = c.component(.day,   from: d)
        return String(format: "daily_best_%04d%02d%02d", y, m, day)
    }

    func bestScore() -> Int {
        UserDefaults.standard.integer(forKey: storageKey)
    }

    /// Saves only if `score` beats the current best. Returns true if it's a new record.
    @discardableResult
    func tryUpdateBest(_ score: Int) -> Bool {
        guard score > bestScore() else { return false }
        UserDefaults.standard.set(score, forKey: storageKey)
        return true
    }

    var bestDisplayText: String {
        let b = bestScore()
        return b > 0 ? "今日最高：\(b) 張" : ""
    }
}
