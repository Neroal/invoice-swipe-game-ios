import SwiftUI

@MainActor
final class LeaderboardViewModel: ObservableObject {

    @Published var selectedMode: GCLeaderboard = .daily
    @Published var entries: [LeaderboardEntry] = []
    @Published var localOutsideTop: LeaderboardEntry? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    private var loadedAvatarIDs: Set<String> = []

    func load(mode: GCLeaderboard? = nil) {
        let target = mode ?? selectedMode
        selectedMode = target
        entries = []
        localOutsideTop = nil
        errorMessage = nil
        isLoading = true

        Task {
            let gc = GameCenterManager.shared
            guard gc.isAuthenticated else {
                isLoading = false
                errorMessage = "請先登入 Game Center"
                return
            }
            let (newEntries, localEntry) = await gc.loadTopEntries(for: target, count: 20)
            isLoading = false
            if newEntries.isEmpty && localEntry == nil {
                errorMessage = "目前尚無排行榜資料"
                return
            }
            entries = newEntries
            localOutsideTop = localEntry
            await loadAvatars(for: newEntries + (localEntry.map { [$0] } ?? []), mode: target)
        }
    }

    private func loadAvatars(for items: [LeaderboardEntry], mode: GCLeaderboard) async {
        let gc = GameCenterManager.shared
        for item in items {
            guard mode == selectedMode else { return }
            guard !loadedAvatarIDs.contains(item.id) else { continue }
            if let image = await gc.loadAvatar(for: item.id) {
                loadedAvatarIDs.insert(item.id)
                applyAvatar(image, to: item.id)
            }
        }
    }

    private func applyAvatar(_ image: UIImage, to playerID: String) {
        if let i = entries.firstIndex(where: { $0.id == playerID }) {
            entries[i].avatar = image
        }
        if localOutsideTop?.id == playerID {
            localOutsideTop?.avatar = image
        }
    }
}
