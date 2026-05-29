import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case daily   = "daily"
    case normal  = "normal"
    case endless = "endless"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .normal:  return "一般模式"
        case .daily:   return "每日挑戰"
        case .endless: return "無限模式"
        }
    }

    var systemIcon: String {
        switch self {
        case .normal:  return "stopwatch"
        case .daily:   return "calendar"
        case .endless: return "infinity"
        }
    }

    var description: String {
        switch self {
        case .daily:   return "全球同一題，每天限 3 次"
        case .normal:  return "30 秒限時，拼加權分數"
        case .endless: return "3 條命，衝最長連續紀錄"
        }
    }

    var hasTimer: Bool { self != .endless }

    var gcLeaderboard: GCLeaderboard {
        switch self {
        case .normal:  return .normal
        case .daily:   return .daily
        case .endless: return .endless
        }
    }
}
