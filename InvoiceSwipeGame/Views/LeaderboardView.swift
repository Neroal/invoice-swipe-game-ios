import SwiftUI

struct LeaderboardView: View {
    @StateObject private var vm = LeaderboardViewModel()
    @Environment(\.dismiss) private var dismiss

    private let modes: [GCLeaderboard] = [.daily, .normal, .endless]

    var body: some View {
        ZStack {
            Color.gameBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("排行榜")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .tracking(3)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(10)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)

                // Mode tabs
                HStack(spacing: 8) {
                    ForEach(modes, id: \.rawValue) { mode in
                        Button {
                            if vm.selectedMode != mode { vm.load(mode: mode) }
                        } label: {
                            Text(mode.displayName)
                                .font(.system(size: 12, weight: .bold))
                                .tracking(1)
                                .foregroundColor(vm.selectedMode == mode ? Color.gameBg : .white.opacity(0.5))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(vm.selectedMode == mode ? Color.gameGold : Color.white.opacity(0.06))
                                .cornerRadius(20)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 14)

                Divider().background(Color.white.opacity(0.08))

                // Content
                if vm.isLoading {
                    Spacer()
                    ProgressView()
                        .tint(Color.gameGold)
                    Spacer()
                } else if let error = vm.errorMessage {
                    Spacer()
                    Text(error)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.4))
                        .multilineTextAlignment(.center)
                        .padding(32)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(vm.entries) { entry in
                                LeaderboardRowView(entry: entry, mode: vm.selectedMode)
                                Divider().background(Color.white.opacity(0.05)).padding(.leading, 60)
                            }
                            // Local player outside top 20
                            if let local = vm.localOutsideTop {
                                Divider().background(Color.white.opacity(0.15)).padding(.vertical, 4)
                                LeaderboardRowView(entry: local, mode: vm.selectedMode)
                            }
                        }
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .onAppear { vm.load() }
    }
}

// MARK: – Row

private struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let mode: GCLeaderboard

    var rankColor: Color {
        switch entry.rank {
        case 1: return Color.gameGold
        case 2: return Color(hex: "c0c0c0")
        case 3: return Color(hex: "cd7f32")
        default: return .white.opacity(0.4)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Rank
            Text(entry.rank <= 3 ? rankEmoji : "#\(entry.rank)")
                .font(.system(size: entry.rank <= 3 ? 20 : 14, weight: .black))
                .foregroundColor(rankColor)
                .frame(width: 36, alignment: .center)

            // Avatar
            AvatarView(image: entry.avatar, isLocalPlayer: entry.isLocalPlayer)

            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.playerName)
                    .font(.system(size: 14, weight: entry.isLocalPlayer ? .heavy : .medium))
                    .foregroundColor(entry.isLocalPlayer ? Color.gameGold : .white)
                    .lineLimit(1)
                if entry.isLocalPlayer {
                    Text("你")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.gameGold.opacity(0.7))
                        .tracking(1)
                }
            }

            Spacer()

            // Score
            Text(mode.formatScore(entry.score))
                .font(.system(size: 15, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(entry.isLocalPlayer ? Color.gameGold.opacity(0.06) : Color.clear)
    }

    private var rankEmoji: String {
        switch entry.rank {
        case 1: return "🥇"
        case 2: return "🥈"
        case 3: return "🥉"
        default: return "#\(entry.rank)"
        }
    }
}

// MARK: – Avatar

private struct AvatarView: View {
    let image: UIImage?
    let isLocalPlayer: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(isLocalPlayer ? Color.gameGold.opacity(0.2) : Color.white.opacity(0.08))
                .frame(width: 36, height: 36)
            if let img = image {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }
}
