import SwiftUI

extension Color {
    // MARK: – Background
    static let gameBg   = Color(red: 0.059, green: 0.059, blue: 0.102)  // 0f0f1a
    static let panelBg  = Color(red: 0.102, green: 0.102, blue: 0.180)  // 1a1a2e
    static let cardBg   = Color(red: 0.996, green: 0.976, blue: 0.933)  // fef9ee

    // MARK: – Brand
    static let accent   = Color(red: 0.914, green: 0.271, blue: 0.376)  // e94560
    static let gameGold = Color(red: 0.961, green: 0.651, blue: 0.137)  // f5a623
    static let stampRed = Color(red: 0.800, green: 0.133, blue: 0.000)  // cc2200

    // MARK: – Feedback
    static let successGreen = Color(hex: "2ecc71")
    static let errorRed     = Color(hex: "e74c3c")

    // MARK: – Combo phases
    static let comboPurple     = Color(hex: "a78bfa")  // phase 1
    static let comboDeepOrange = Color(hex: "ff4400")  // phase 3
    static let comboBrightRed  = Color(hex: "ff1111")  // phase 4

    // MARK: – Win tiers
    static let winDefault = Color(hex: "00ffaa")
    static let winSpecial = Color(hex: "ff4444")
    static let winGrand   = Color(hex: "ffaa00")

    // MARK: – Mode indicator
    static let dailyBlue = Color(hex: "4fc3f7")
}
