import SwiftUI

struct StartView: View {
    @EnvironmentObject var vm: GameViewModel
    @ObservedObject private var gc = GameCenterManager.shared
    @State private var showLeaderboard = false

    var body: some View {
        ZStack {
            Color.gameBg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    Spacer(minLength: 44)

                    // Title
                    VStack(spacing: 4) {
                        Text("發票對對碰")
                            .font(.system(size: 64, weight: .black, design: .default))
                            .foregroundColor(.white)
                            .shadow(color: Color.accent, radius: 0, x: 4, y: 4)
                        Text("INVOICE SWIPE CHALLENGE")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.35))
                            .tracking(4)
                    }

                    // Demo hint
                    HStack(spacing: 14) {
                        DemoBadgeView(text: "← 未中", isWin: false)
                        Image(systemName: "doc.plaintext")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.45))
                        DemoBadgeView(text: "中獎 →", isWin: true)
                    }

                    // Mode cards
                    VStack(spacing: 10) {
                        ForEach(GameMode.allCases) { mode in
                            ModeCardView(mode: mode)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Bottom action row
                    HStack(spacing: 12) {
                        Button { vm.showSettings = true } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "gearshape.fill")
                                Text("設定")
                            }
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 9)
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1))
                        }
                        .hapticTap()

                        if gc.isAuthenticated {
                            Button { showLeaderboard = true } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "trophy.fill")
                                    Text("排行榜")
                                }
                                .font(.system(size: 13))
                                .foregroundColor(Color.gameGold.opacity(0.8))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 9)
                                .overlay(RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gameGold.opacity(0.25), lineWidth: 1))
                            }
                            .hapticTap()
                        }
                    }
                    .sheet(isPresented: $showLeaderboard) {
                        LeaderboardView()
                    }

                    Spacer(minLength: 40)
                }
            }
        }
    }
}

// MARK: – Sub-views

private struct DemoBadgeView: View {
    let text: String; let isWin: Bool
    var body: some View {
        Text(text)
            .font(.system(size: 13, weight: .bold))
            .tracking(1)
            .foregroundColor(isWin ? Color.successGreen : Color.errorRed)
            .padding(.horizontal, 14).padding(.vertical, 7)
            .background((isWin ? Color.successGreen : Color.errorRed).opacity(0.12))
            .overlay(RoundedRectangle(cornerRadius: 4)
                .stroke((isWin ? Color.successGreen : Color.errorRed).opacity(0.3), lineWidth: 1))
            .cornerRadius(4)
    }
}

private struct ModeCardView: View {
    @EnvironmentObject var vm: GameViewModel
    @ObservedObject private var gc = GameCenterManager.shared
    let mode: GameMode

    private var isDailyDisabled: Bool {
        mode == .daily && !vm.canPlayDaily
    }

    var body: some View {
        Button { vm.selectMode(mode) } label: {
            HStack(spacing: 14) {
                Image(systemName: mode.systemIcon)
                    .font(.system(size: 22))
                    .foregroundColor(isDailyDisabled ? .white.opacity(0.25) : Color.accent)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.system(size: 15, weight: .heavy))
                        .foregroundColor(isDailyDisabled ? .white.opacity(0.35) : .white)
                        .tracking(2)
                    Text(mode.description)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.35))
                        .multilineTextAlignment(.leading)
                    if mode == .daily {
                        if !vm.dailyBestText.isEmpty {
                            Text(vm.dailyBestText)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(Color.gameGold)
                        }
                        Text(vm.dailyAttemptsText)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(
                                vm.canPlayDaily
                                    ? Color.dailyBlue
                                    : Color.errorRed
                            )
                    }
                }
                Spacer()
                if gc.isAuthenticated, let rank = gc.modeRanks[mode.gcLeaderboard] {
                    Text("全球 #\(rank)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.gameGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gameGold.opacity(0.1))
                        .cornerRadius(10)
                }
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(isDailyDisabled ? 0.08 : 0.2))
            }
            .padding(16)
            .background(Color.white.opacity(isDailyDisabled ? 0.02 : 0.04))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(isDailyDisabled ? 0.05 : 0.1), lineWidth: 1.5))
            .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(isDailyDisabled)
        .hapticTap(style: .medium)
    }
}
