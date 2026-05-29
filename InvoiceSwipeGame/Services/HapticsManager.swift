import UIKit

/// Centralises all haptic feedback for the game.
/// Uses UIKit feedback generators — no CoreHaptics required (works on all iOS 16+ devices).
final class HapticsManager {

    // MARK: – Generators (pre-warmed for low latency)
    private let light   = UIImpactFeedbackGenerator(style: .light)
    private let medium  = UIImpactFeedbackGenerator(style: .medium)
    private let heavy   = UIImpactFeedbackGenerator(style: .heavy)
    private let notif   = UINotificationFeedbackGenerator()

    init() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        notif.prepare()
    }

    // MARK: – Public API

    /// 滑動卡片時的輕觸感
    func swipe()     { light.impactOccurred() }

    /// 答對：成功通知震動
    func correct()   { notif.notificationOccurred(.success) }

    /// 答錯：錯誤通知震動
    func wrong()     { notif.notificationOccurred(.error) }

    /// 小獎（六獎～二獎）：中等震動
    func coin()      { medium.impactOccurred() }

    /// 失命：連續三下由強到弱，配合音效節奏
    func lifeLost() {
        heavy.impactOccurred(intensity: 1.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.13) { [weak self] in
            self?.heavy.impactOccurred(intensity: 0.7)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.26) { [weak self] in
            self?.heavy.impactOccurred(intensity: 0.4)
        }
    }

    /// 大獎演出：依獎項等級給對應強度
    func bigWin(tier: WinTier) {
        switch tier {
        case .first:
            heavy.impactOccurred(intensity: 0.8)
        case .grand:
            heavy.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.heavy.impactOccurred(intensity: 0.9)
            }
        case .special:
            // 三連強震，配合爆炸動畫
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.10) { [weak self] in
                    self?.heavy.impactOccurred(intensity: 1.0)
                }
            }
        default:
            break
        }
    }

    /// 倒數 beep
    func beep(heavy isHeavy: Bool) {
        if isHeavy { medium.impactOccurred(intensity: 0.9) }
        else       { light.impactOccurred(intensity: 0.6)  }
    }

    /// 最後 5 秒 tick
    func tick() { light.impactOccurred(intensity: 0.4) }

    /// 時間到
    func timeUp() { notif.notificationOccurred(.warning) }

    /// Combo 里程碑：震動強度隨 streak 升高
    func comboMilestone(streak: Int) {
        switch streak {
        case ..<5:
            medium.impactOccurred(intensity: 0.6)
        case 5..<8:
            medium.impactOccurred(intensity: 0.8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.medium.impactOccurred(intensity: 0.6)
            }
        case 8..<10:
            heavy.impactOccurred(intensity: 0.7)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.heavy.impactOccurred(intensity: 0.85)
            }
        default: // 10+
            heavy.impactOccurred(intensity: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.heavy.impactOccurred(intensity: 1.0)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) { [weak self] in
                self?.heavy.impactOccurred(intensity: 0.8)
            }
        }
    }

    /// Combo 中斷：警告型通知震動
    func comboBreak() { notif.notificationOccurred(.warning) }
}
