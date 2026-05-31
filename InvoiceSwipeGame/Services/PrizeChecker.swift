import Foundation

struct PrizeChecker {

    static let sellers: [String] = [
        "全家便利商店", "7-ELEVEN", "麥當勞", "摩斯漢堡", "星巴克",
        "誠品書店", "全聯福利中心", "家樂福", "IKEA", "大潤發",
        "路易莎咖啡", "爭鮮迴轉壽司", "85度C", "康是美", "寶雅"
    ]

    static let itemNames: [String] = [
        "美式咖啡", "拿鐵咖啡", "手搖飲料", "御飯糰", "三明治",
        "雞腿便當", "炸雞腿", "薯條", "漢堡套餐", "凱薩沙拉",
        "書籍雜誌", "文具用品", "日用百貨", "零食飲料", "保養品"
    ]

    private static let letterPool = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")

    // MARK: – Check

    static func check(number: String, prizes: PrizeNumbers) -> WinTier? {
        guard number.count == 8 else { return nil }
        if number == prizes.special { return .special }
        if number == prizes.grand   { return .grand   }
        // 三組頭獎：從高獎級往低逐一比對，最先命中者為準
        for f in prizes.firsts { if number          == f          { return .first  } }
        for f in prizes.firsts { if number.suffix(7) == f.suffix(7) { return .second } }
        for f in prizes.firsts { if number.suffix(6) == f.suffix(6) { return .third  } }
        for f in prizes.firsts { if number.suffix(5) == f.suffix(5) { return .fourth } }
        for f in prizes.firsts { if number.suffix(4) == f.suffix(4) { return .fifth  } }
        for f in prizes.firsts { if number.suffix(3) == f.suffix(3) { return .sixth  } }
        return nil
    }

    // MARK: – Generation helpers

    static func rand8(rng: inout SeededRNG) -> String {
        String(format: "%08d", Int(rng.next() * 100_000_000))
    }

    static func generatePrizeNumbers(rng: inout SeededRNG) -> PrizeNumbers {
        PrizeNumbers(
            special: rand8(rng: &rng),
            grand:   rand8(rng: &rng),
            first1:  rand8(rng: &rng),
            first2:  rand8(rng: &rng),
            first3:  rand8(rng: &rng)
        )
    }

    /// 每個月的天數（簡化：非二月皆用 30/31，二月用 28）
    private static func daysInMonth(_ month: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: return 31
        case 4, 6, 9, 11:            return 30
        default:                      return 28   // 2 月
        }
    }

    // MARK: – Win rates per mode
    // normal/endless: 70%；daily: 35%（強調準確度）
    static func winRate(for mode: GameMode) -> Double {
        switch mode {
        case .normal:  return 0.70
        case .daily:   return 0.35
        case .endless: return 0.70
        }
    }

    // MARK: – Prize tier distribution per mode
    // 累積機率表；daily 偏重高獎讓金額差異更大，normal/endless 偏重四/五獎維持穩定節奏
    static func pickWinningNumber(prizes: PrizeNumbers, rng: inout SeededRNG, mode: GameMode, isBurst: Bool) -> String {
        let t = rng.next()
        let f = rng.nextElement(prizes.firsts)

        if isBurst {
            // 爆發視窗：強制三獎以上
            if      t < 0.05 { return prizes.special }
            else if t < 0.15 { return prizes.grand   }
            else if t < 0.45 { return f }
            else if t < 0.72 { return String(rand8(rng: &rng).prefix(1)) + f.suffix(7) }
            else              { return String(rand8(rng: &rng).prefix(2)) + f.suffix(6) }
        }

        switch mode {
        case .daily:
            // 高獎偏重：特別2%、特5%、頭8%、二10%、三12%、四25%、五16%、六22%（加總100%）
            // 累積：.02 / .07 / .15 / .25 / .37 / .62 / .78 / 1.0
            if      t < 0.02 { return prizes.special }
            else if t < 0.07 { return prizes.grand   }
            else if t < 0.15 { return f }
            else if t < 0.25 { return String(rand8(rng: &rng).prefix(1)) + f.suffix(7) }
            else if t < 0.37 { return String(rand8(rng: &rng).prefix(2)) + f.suffix(6) }
            else if t < 0.62 { return String(rand8(rng: &rng).prefix(3)) + f.suffix(5) }
            else if t < 0.78 { return String(rand8(rng: &rng).prefix(4)) + f.suffix(4) }
            else              { return String(rand8(rng: &rng).prefix(5)) + f.suffix(3) }

        case .normal, .endless:
            // 偏重四/五獎：特別2%、特4%、頭9%、二10%、三10%、四25%、五30%、六10%
            // 累積：.02 / .06 / .15 / .25 / .35 / .60 / .90 / 1.0
            if      t < 0.02 { return prizes.special }
            else if t < 0.06 { return prizes.grand   }
            else if t < 0.15 { return f }
            else if t < 0.25 { return String(rand8(rng: &rng).prefix(1)) + f.suffix(7) }
            else if t < 0.35 { return String(rand8(rng: &rng).prefix(2)) + f.suffix(6) }
            else if t < 0.60 { return String(rand8(rng: &rng).prefix(3)) + f.suffix(5) }
            else if t < 0.90 { return String(rand8(rng: &rng).prefix(4)) + f.suffix(4) }
            else              { return String(rand8(rng: &rng).prefix(5)) + f.suffix(3) }
        }
    }

    static func generateInvoice(prizes: PrizeNumbers, rng: inout SeededRNG, mode: GameMode, isBurst: Bool = false) -> Invoice {
        let cal     = Calendar.current
        let today   = Date()
        let rocYear = cal.component(.year, from: today) - 1911
        let curMonth     = cal.component(.month, from: today)
        let periodStart  = curMonth % 2 == 0 ? curMonth - 1 : curMonth
        let periodEnd    = periodStart + 1
        let month = rng.next() < 0.5 ? periodStart : periodEnd
        let day   = rng.nextInt(1...daysInMonth(month))
        let dateStr = "\(rocYear).\(String(format: "%02d", month)).\(String(format: "%02d", day))"
        let seller  = rng.nextElement(sellers)
        let amount  = rng.nextInt(5...300) * 100
        let letterPrefix = String(rng.nextElement(letterPool)) + String(rng.nextElement(letterPool))
        let taxId   = rand8(rng: &rng)
        let itemName = rng.nextElement(itemNames)
        let invoiceCopy = rng.next() < 0.5 ? "消費者聯" : "收執聯"

        let forceWin = isBurst || rng.next() < winRate(for: mode)
        var number: String

        if forceWin {
            number = pickWinningNumber(prizes: prizes, rng: &rng, mode: mode, isBurst: isBurst)
        } else {
            var attempts = 0
            repeat {
                number = rand8(rng: &rng)
                attempts += 1
            } while check(number: number, prizes: prizes) != nil && attempts < 200
        }

        let tier = check(number: number, prizes: prizes)
        return Invoice(
            number: number,
            letterPrefix: letterPrefix,
            isWinner: tier != nil,
            winTier: tier,
            seller: seller,
            taxId: taxId,
            itemName: itemName,
            amount: amount,
            dateString: dateStr,
            invoiceCopy: invoiceCopy
        )
    }
}
