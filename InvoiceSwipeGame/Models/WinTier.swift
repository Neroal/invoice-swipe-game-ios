import Foundation

enum WinTier: String, CaseIterable {
    case special = "特別獎"
    case grand   = "特獎"
    case first   = "頭獎"
    case second  = "二獎"
    case third   = "三獎"
    case fourth  = "四獎"
    case fifth   = "五獎"
    case sixth   = "六獎"

    var prizeAmount: Int {
        switch self {
        case .special: return 10_000_000
        case .grand:   return  2_000_000
        case .first:   return    200_000
        case .second:  return     40_000
        case .third:   return     10_000
        case .fourth:  return      4_000
        case .fifth:   return      1_000
        case .sixth:   return        200
        }
    }

    var isBigWin: Bool { [.special, .grand, .first].contains(self) }

    /// 基礎 +2 之外的額外加分，各獎級遞增
    var bonusPoints: Int {
        switch self {
        case .special: return 10  // 共 +12
        case .grand:   return 8   // 共 +10
        case .first:   return 6   // 共 +8
        case .second:  return 5   // 共 +7
        case .third:   return 4   // 共 +6
        case .fourth:  return 3   // 共 +5
        case .fifth:   return 2   // 共 +4
        case .sixth:   return 1   // 共 +3
        }
    }

    /// Badge 顯示文字，以分數取代獎金金額
    var scoreText: String { "+\(2 + bonusPoints)分" }

    var amountString: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return "NT$ \(f.string(from: NSNumber(value: prizeAmount)) ?? "")"
    }

    var matchLength: Int {
        switch self {
        case .special, .grand, .first: return 8
        case .second:  return 7
        case .third:   return 6
        case .fourth:  return 5
        case .fifth:   return 4
        case .sixth:   return 3
        }
    }
}
