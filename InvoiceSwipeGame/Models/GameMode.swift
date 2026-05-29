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
        case .daily:   return "全球同一份題，每天 3 次"
        case .normal:  return "30 秒限時，拼中獎總金額"
        case .endless: return "3 條命，拼最長連擊"
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
