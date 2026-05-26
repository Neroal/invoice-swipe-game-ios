import Foundation

struct PrizeChecker {

    static let sellers: [String] = [
        "全家便利商店", "7-ELEVEN", "麥當勞", "摩斯漢堡", "星巴克",
        "誠品書店", "全聯福利中心", "家樂福", "IKEA", "大潤發",
        "路易莎咖啡", "爭鮮迴轉壽司", "85度C", "康是美", "寶雅"
    ]

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

    static func generateInvoice(prizes: PrizeNumbers, rng: inout SeededRNG) -> Invoice {
        let cal     = Calendar.current
        let today   = Date()
        let rocYear = cal.component(.year, from: today) - 1911
        // 統一發票開獎以奇數月為起始，例如 5–6 月期
        let curMonth     = cal.component(.month, from: today)
        let periodStart  = curMonth % 2 == 0 ? curMonth - 1 : curMonth   // 奇數起始月
        let periodEnd    = periodStart + 1                                 // 偶數結束月
        // 隨機選本期其中一個月，再隨機選日期
        let month = rng.next() < 0.5 ? periodStart : periodEnd
        let day   = rng.nextInt(1...daysInMonth(month))
        let dateStr = "\(rocYear).\(String(format: "%02d", month)).\(String(format: "%02d", day))"
        let seller  = rng.nextElement(sellers)
        let amount  = rng.nextInt(5...300) * 100

        let forceWin = rng.next() < 0.35
        var number: String

        if forceWin {
            let t = rng.next()
            // 隨機從三組頭獎中選一組作為本次中獎號碼的基底
            let f = rng.nextElement(prizes.firsts)
            if      t < 0.02 { number = prizes.special }
            else if t < 0.06 { number = prizes.grand   }
            else if t < 0.16 { number = f }
            else if t < 0.33 { number = String(rand8(rng: &rng).prefix(1)) + f.suffix(7) }
            else if t < 0.50 { number = String(rand8(rng: &rng).prefix(2)) + f.suffix(6) }
            else if t < 0.65 { number = String(rand8(rng: &rng).prefix(3)) + f.suffix(5) }
            else if t < 0.82 { number = String(rand8(rng: &rng).prefix(4)) + f.suffix(4) }
            else              { number = String(rand8(rng: &rng).prefix(5)) + f.suffix(3) }
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
            isWinner: tier != nil,
            winTier: tier,
            seller: seller,
            amount: amount,
            dateString: dateStr
        )
    }
}
