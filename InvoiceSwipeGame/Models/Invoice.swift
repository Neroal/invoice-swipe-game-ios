import Foundation

struct Invoice: Identifiable {
    let id = UUID()
    let number: String
    let isWinner: Bool
    let winTier: WinTier?
    let seller: String
    let amount: Int
    let dateString: String   // e.g. "114.05.12"
}
