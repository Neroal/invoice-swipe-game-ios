import Foundation

struct Invoice: Identifiable {
    let id = UUID()
    let number: String          // 8 digits, for prize checking
    let letterPrefix: String    // e.g., "AB"
    let isWinner: Bool
    let winTier: WinTier?
    let seller: String
    let taxId: String           // 8-digit seller tax number
    let itemName: String
    let amount: Int             // total incl. 5% VAT
    let dateString: String      // e.g., "114.05.12"
    let invoiceCopy: String     // "消費者聯" or "收執聯"

    var subtotal: Int { Int(Double(amount) / 1.05) }
    var tax: Int { amount - subtotal }
    var displayNumber: String { "\(letterPrefix)-\(number)" }
    var rocDateString: String {
        let parts = dateString.split(separator: ".")
        guard parts.count == 3 else { return dateString }
        return "民國\(parts[0])年\(parts[1])月\(parts[2])日"
    }
}
