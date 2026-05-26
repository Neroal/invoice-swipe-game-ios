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
