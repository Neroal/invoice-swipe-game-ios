import GameKit
import SwiftUI

// MARK: - Entry model

struct LeaderboardEntry: Identifiable {
    let id: String          // gamePlayerID
    let rank: Int
    let score: Int
    let playerName: String
    var avatar: UIImage? = nil
    let isLocalPlayer: Bool
}

// MARK: - Leaderboard IDs

enum GCLeaderboard: String, CaseIterable {
    case normal  = "invoice.normal.score"
    case daily   = "invoice.daily.score.v2"
    case endless = "invoice.endless.streak"

    var timeScope: GKLeaderboard.TimeScope {
        self == .daily ? .today : .allTime
    }

    var displayName: String {
        switch self {
        case .normal:  return "一般模式"
        case .daily:   return "每日挑戰"
        case .endless: return "無限模式"
        }
    }

    func formatScore(_ score: Int) -> String {
        switch self {
        case .normal, .daily:
            return "NT$ \(score.formatted())"
        case .endless:
            return "Combo \(score / 1000)"
        }
    }
}

// MARK: - Manager

@MainActor
final class GameCenterManager: ObservableObject {

    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var authVC: UIViewController? = nil
    @Published var showAuthSheet = false
    @Published var modeRanks: [GCLeaderboard: Int] = [:]

    // MARK: - Authentication

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            guard let self else { return }
            Task { @MainActor in
                if let vc = viewController {
                    self.authVC = vc
                    self.showAuthSheet = true
                } else if GKLocalPlayer.local.isAuthenticated {
                    self.isAuthenticated = true
                    self.authVC = nil
                    self.showAuthSheet = false
                    await self.fetchModeRanks()
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
                await fetchModeRanks()
            } catch {
                print("[GameCenter] 分數上傳失敗 (\(leaderboard.rawValue)): \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Mode rank cache (for StartView badges)

    func fetchModeRanks() async {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        for mode in GCLeaderboard.allCases {
            if let rank = await fetchLocalPlayerRank(for: mode) {
                modeRanks[mode] = rank
            }
        }
    }

    private func fetchLocalPlayerRank(for leaderboard: GCLeaderboard) async -> Int? {
        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboard.rawValue])
            guard let board = boards.first else { return nil }
            let (localEntry, _, _) = try await board.loadEntries(
                for: .global, timeScope: leaderboard.timeScope, range: NSRange(1...1)
            )
            guard let rank = localEntry?.rank, rank > 0 else { return nil }
            return rank
        } catch {
            print("[GameCenter] 排名查詢失敗 (\(leaderboard.rawValue)): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Result screen: local rank + neighbors

    func loadResultRankAndNeighbors(for leaderboard: GCLeaderboard) async -> (local: LeaderboardEntry?, above: LeaderboardEntry?, below: LeaderboardEntry?) {
        guard GKLocalPlayer.local.isAuthenticated else { return (nil, nil, nil) }
        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboard.rawValue])
            guard let board = boards.first else { return (nil, nil, nil) }

            let (localGKEntry, _, totalCount) = try await board.loadEntries(
                for: .global, timeScope: leaderboard.timeScope, range: NSRange(1...1)
            )
            guard let localGKEntry, localGKEntry.rank > 0 else { return (nil, nil, nil) }

            let local = LeaderboardEntry(
                id: localGKEntry.player.gamePlayerID,
                rank: localGKEntry.rank,
                score: localGKEntry.score,
                playerName: localGKEntry.player.displayName,
                isLocalPlayer: true
            )

            let rank = localGKEntry.rank
            guard totalCount > 1 else { return (local, nil, nil) }

            let startPos = max(1, rank - 1)
            let endPos   = min(totalCount, rank + 1)

            let (_, neighborGKEntries, _) = try await board.loadEntries(
                for: .global, timeScope: leaderboard.timeScope, range: NSRange(startPos...endPos)
            )

            let above = neighborGKEntries.first(where: { $0.rank == rank - 1 }).map {
                LeaderboardEntry(id: $0.player.gamePlayerID, rank: $0.rank, score: $0.score, playerName: $0.player.displayName, isLocalPlayer: false)
            }
            let below = neighborGKEntries.first(where: { $0.rank == rank + 1 }).map {
                LeaderboardEntry(id: $0.player.gamePlayerID, rank: $0.rank, score: $0.score, playerName: $0.player.displayName, isLocalPlayer: false)
            }
            return (local, above, below)
        } catch {
            print("[GameCenter] 鄰近玩家載入失敗: \(error.localizedDescription)")
            return (nil, nil, nil)
        }
    }

    // MARK: - Standalone leaderboard: top entries

    func loadTopEntries(for leaderboard: GCLeaderboard, count: Int = 20) async -> (entries: [LeaderboardEntry], localOutsideTop: LeaderboardEntry?) {
        guard GKLocalPlayer.local.isAuthenticated else { return ([], nil) }
        do {
            let boards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboard.rawValue])
            guard let board = boards.first else { return ([], nil) }
            let safeCount = max(1, count)
            let (localGKEntry, topGKEntries, _) = try await board.loadEntries(
                for: .global, timeScope: leaderboard.timeScope, range: NSRange(1...safeCount)
            )
            let localPlayerID = GKLocalPlayer.local.gamePlayerID
            let entries: [LeaderboardEntry] = topGKEntries.map { e in
                playerCache[e.player.gamePlayerID] = e.player
                return LeaderboardEntry(
                    id: e.player.gamePlayerID,
                    rank: e.rank,
                    score: e.score,
                    playerName: e.player.displayName,
                    isLocalPlayer: e.player.gamePlayerID == localPlayerID
                )
            }
            var localOutsideTop: LeaderboardEntry? = nil
            if let e = localGKEntry,
               !topGKEntries.contains(where: { $0.player.gamePlayerID == localPlayerID }) {
                localOutsideTop = LeaderboardEntry(
                    id: e.player.gamePlayerID,
                    rank: e.rank,
                    score: e.score,
                    playerName: e.player.displayName,
                    isLocalPlayer: true
                )
            }
            return (entries, localOutsideTop)
        } catch {
            print("[GameCenter] 排行榜載入失敗 (\(leaderboard.rawValue)): \(error.localizedDescription)")
            return ([], nil)
        }
    }

    // MARK: - Player cache & avatar loading

    private var playerCache: [String: GKPlayer] = [:]

    func loadAvatar(for playerID: String) async -> UIImage? {
        guard let player = playerCache[playerID] else { return nil }
        return try? await player.loadPhoto(for: .small)
    }

    // MARK: - Present native leaderboard overlay

    func presentLeaderboard(_ leaderboard: GCLeaderboard, from root: UIViewController) {
        guard GKLocalPlayer.local.isAuthenticated else { return }
        let vc = GKGameCenterViewController(
            leaderboardID: leaderboard.rawValue,
            playerScope: .global,
            timeScope: leaderboard.timeScope
        )
        vc.gameCenterDelegate = LeaderboardDismissDelegate.shared
        root.present(vc, animated: true)
    }
}

// MARK: - Dismiss delegate

private final class LeaderboardDismissDelegate: NSObject, GKGameCenterControllerDelegate {
    static let shared = LeaderboardDismissDelegate()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

// MARK: - SwiftUI helper: Game Center auth sheet

struct GameCenterAuthView: UIViewControllerRepresentable {
    let viewController: UIViewController
    func makeUIViewController(context: Context) -> UIViewController { viewController }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

// MARK: - SwiftUI button helper: 開啟原生排行榜

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
