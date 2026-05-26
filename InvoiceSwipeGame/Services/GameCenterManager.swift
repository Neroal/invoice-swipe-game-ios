import GameKit
import SwiftUI

// MARK: - Leaderboard IDs
// 請在 App Store Connect > 你的 App > Services > Game Center 建立這三個排行榜，
// 並確認 ID 與下方常數一致。
enum GCLeaderboard: String {
    case normal  = "invoice.normal.score"    // 一般模式：30 秒判斷張數
    case daily   = "invoice.daily.score"     // 每日挑戰：30 秒判斷張數
    case endless = "invoice.endless.streak"  // 無限模式：最長連續答對張數
}

// MARK: - Manager

@MainActor
final class GameCenterManager: ObservableObject {

    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    /// 傳入需要顯示的 view controller（Game Center 登入畫面）
    @Published var authVC: UIViewController? = nil
    @Published var showAuthSheet = false

    // MARK: - Authentication

    /// 在 App 啟動時呼叫一次
    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            Task { @MainActor in
                if let vc = viewController {
                    // 需要讓玩家登入，保存 VC 讓 App 層彈出
                    self.authVC = vc
                    self.showAuthSheet = true
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.isAuthenticated = true
                    self.authVC = nil
                    self.showAuthSheet = false
                } else {
                    self.isAuthenticated = false
                    if let e = error {
                        print("[GameCenter] 認證失敗: \(e.localizedDescription)")
                    }
                }
            }
        }
    }

    // MARK: - Score submission

    /// 上傳分數；若未認證則靜默略過
    func submitScore(_ score: Int, to leaderboard: GCLeaderboard) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        Task {
            do {
                try await GKLeaderboard.submitScore(
                    score,
                    context: 0,
                    player: GKLocalPlayer.local,
                    leaderboardIDs: [leaderboard.rawValue]
                )
            } catch {
                print("[GameCenter] 分數上傳失敗 (\(leaderboard.rawValue)): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Present leaderboard

    func presentLeaderboard(_ leaderboard: GCLeaderboard, from root: UIViewController) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let vc = GKGameCenterViewController(
            leaderboardID: leaderboard.rawValue,
            playerScope: .global,
            timeScope: .allTime
        )
        vc.gameCenterDelegate = LeaderboardDismissDelegate.shared
        root.present(vc, animated: true)
    }
}

// MARK: - Dismiss delegate (singleton to avoid retain issues)

private final class LeaderboardDismissDelegate: NSObject, GKGameCenterControllerDelegate {
    static let shared = LeaderboardDismissDelegate()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - SwiftUI helper: Game Center auth sheet

/// 包裝 GKGameCenterViewController 供 SwiftUI sheet 使用
struct GameCenterAuthView: UIViewControllerRepresentable {
    let viewController: UIViewController

    func makeUIViewController(context: Context) -> UIViewController { viewController }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - SwiftUI button helper: 開啟排行榜

struct LeaderboardButton: View {
    let title: String
    let leaderboard: GCLeaderboard

    var body: some View {
        Button {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let root  = scene.windows.first?.rootViewController else { return }
            GameCenterManager.shared.presentLeaderboard(leaderboard, from: root)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(1)
            }
            .foregroundColor(Color(hex: "f5a623"))
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Color(hex: "f5a623").opacity(0.1))
            .overlay(RoundedRectangle(cornerRadius: 7)
                .stroke(Color(hex: "f5a623").opacity(0.3), lineWidth: 1))
            .cornerRadius(7)
        }
    }
}
