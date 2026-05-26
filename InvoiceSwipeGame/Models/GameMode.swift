import Foundation

enum GameMode: String, CaseIterable, Identifiable {
    case normal  = "normal"
    case daily   = "daily"
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
        case .normal:  return "30 秒內判斷越多張越好\n考驗眼力與反應速度"
        case .daily:   return "全球同一題，每天更新\n純比反應速度與判斷力"
        case .endless: return "答錯 3 次遊戲結束\n挑戰最長連續答對紀錄"
        }
    }

    var hasTimer: Bool { self != .endless }
}
