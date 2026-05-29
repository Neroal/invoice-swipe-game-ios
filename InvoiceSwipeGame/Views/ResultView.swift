import SwiftUI
import StoreKit

struct ResultView: View {
    @EnvironmentObject var vm: GameViewModel
    @Environment(\.requestReview) private var requestReview
    @State private var formulaPhase = 0
    @State private var rankResult: (local: LeaderboardEntry?, above: LeaderboardEntry?, below: LeaderboardEntry?) = (nil, nil, nil)
    @State private var rankLoaded = false

    var body: some View {
        ZStack {
            Color.gameBg.ignoresSafeArea()

            VStack(spacing: 20) {
                // Title
                Text(titleText)
                    .font(.system(size: 52, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: Color.gameGold, radius: 0, x: 3, y: 3)
                    .tracking(4)

                // New record banner
                if vm.isNewDailyRecord {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                        Text("今日新紀錄！")
                    }
                        .font(.system(size: 13, weight: .black))
                        .tracking(3)
                        .foregroundColor(.white)
                        .padding(.horizontal, 22).padding(.vertical, 7)
                        .background(
                            LinearGradient(colors: [Color.gameGold, Color.accent],
                                           startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(20)
                        .transition(.scale.combined(with: .opacity))
                }

                // Stats card
                statsCard
                    .onAppear {
                        formulaPhase = 0
                        if vm.currentMode == .daily {
                            Task {
                                try? await Task.sleep(nanoseconds: 300_000_000)
                                withAnimation(.spring(dampingFraction: 0.7)) { formulaPhase = 1 }
                                try? await Task.sleep(nanoseconds: 550_000_000)
                                withAnimation(.spring(dampingFraction: 0.7)) { formulaPhase = 2 }
                                try? await Task.sleep(nanoseconds: 550_000_000)
                                withAnimation(.spring(dampingFraction: 0.7)) { formulaPhase = 3 }
                                try? await Task.sleep(nanoseconds: 700_000_000)
                                withAnimation(.easeIn(duration: 0.3)) { formulaPhase = 4 }
                            }
                        }
                    }
                    .task {
                        let result = await GameCenterManager.shared
                            .loadResultRankAndNeighbors(for: vm.currentMode.gcLeaderboard)
                        withAnimation(.easeIn(duration: 0.3)) {
                            rankResult = result
                            rankLoaded = true
                        }
                    }

                // Buttons
                VStack(spacing: 10) {
                    Button { vm.replayCurrentMode() } label: {
                        Text(replayLabel)
                            .font(.system(size: 15, weight: .black))
                            .tracking(3)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 15)
                            .background(replayDisabled ? Color.white.opacity(0.1) : Color.accent)
                            .cornerRadius(10)
                            .shadow(color: replayDisabled ? .clear : Color(hex: "a0001e"),
                                    radius: 0, x: 0, y: 4)
                    }
                    .disabled(replayDisabled)
                    .hapticTap(style: .medium)
                    Button {
                        // 累積局數 >= 5 且從未觸發過，點回主選單時跳出評分請求
                        if vm.hasReachedReviewThreshold {
                            requestReview()
                            vm.markReviewRequested()
                        }
                        vm.goHome()
                    } label: {
                        Text("回主選單")
                            .font(.system(size: 15, weight: .bold))
                            .tracking(2)
                            .foregroundColor(.white.opacity(0.45))
                            .frame(maxWidth: .infinity).padding(.vertical, 12)
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .hapticTap()
                }
                .padding(.horizontal, 28)
            }
        }
    }

    // MARK: – Stats card
    private var statsCard: some View {
        VStack(spacing: 18) {
            if vm.currentMode == .endless {
                statRow(label: "最長連續答對", value: "\(vm.bestStreak)", color: Color.comboPurple)
                statRow(label: "判斷張數",    value: "\(vm.totalCount)", color: Color.gameGold)
            } else if vm.currentMode == .daily {
                statRow(label: "原始獎金", value: vm.totalPrizeAmountString, color: Color.gameGold)
                    .opacity(formulaPhase >= 1 ? 1 : 0)
                    .offset(y: formulaPhase >= 1 ? 0 : 12)
                    .animation(.spring(dampingFraction: 0.7), value: formulaPhase >= 1)
                statRow(label: "× 準確率", value: "\(vm.accuracy)%", color: Color.dailyBlue)
                    .opacity(formulaPhase >= 2 ? 1 : 0)
                    .offset(y: formulaPhase >= 2 ? 0 : 12)
                    .animation(.spring(dampingFraction: 0.7), value: formulaPhase >= 2)
                statRow(label: "= 最終得分", value: vm.dailyFinalScoreString, color: Color.successGreen)
                    .opacity(formulaPhase >= 3 ? 1 : 0)
                    .offset(y: formulaPhase >= 3 ? 0 : 12)
                    .animation(.spring(dampingFraction: 0.7), value: formulaPhase >= 3)
                statRow(label: "今日最高", value: vm.dailyBestPrizeString, color: Color.comboPurple)
                    .opacity(formulaPhase >= 4 ? 1 : 0)
                    .animation(.easeIn(duration: 0.3), value: formulaPhase >= 4)
                Text(vm.dailyAttemptsText)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(
                        vm.canPlayDaily
                            ? Color.dailyBlue
                            : Color.errorRed
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .opacity(formulaPhase >= 4 ? 1 : 0)
            } else {
                statRow(label: "本局中獎", value: vm.totalPrizeAmountString, color: Color.gameGold)
                statRow(label: "答對張數", value: "\(vm.correctCount)",       color: Color.successGreen)
                statRow(label: "答錯張數", value: "\(vm.wrongCount)",          color: Color.errorRed)
            }

            // Accuracy bar
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("正確率").font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).tracking(2)
                    Spacer()
                    Text("\(vm.accuracy)%").font(.system(size: 32, weight: .black)).foregroundColor(.white)
                }
                AccuracyBar(accuracy: vm.accuracy)
            }

            // Global rank
            if shouldShowRank {
                rankSection
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .padding(28)
        .background(Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(14)
        .padding(.horizontal, 24)
    }

    private var shouldShowRank: Bool {
        guard rankLoaded, let local = rankResult.local, local.rank > 0 else { return false }
        if vm.currentMode == .daily { return formulaPhase >= 4 }
        return true
    }

    private var rankSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider().background(Color.white.opacity(0.1))
            Text("全球名次").font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).tracking(2)
            if let local = rankResult.local {
                VStack(spacing: 4) {
                    if let above = rankResult.above {
                        rankNeighborRow(entry: above, isLocal: false)
                    }
                    rankNeighborRow(entry: local, isLocal: true)
                    if let below = rankResult.below {
                        rankNeighborRow(entry: below, isLocal: false)
                    }
                }
            }
        }
    }

    private func rankNeighborRow(entry: LeaderboardEntry, isLocal: Bool) -> some View {
        HStack(spacing: 10) {
            Text("#\(entry.rank)")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(isLocal ? Color.gameGold : .white.opacity(0.45))
                .frame(width: 44, alignment: .leading)
            Text(isLocal ? "你" : entry.playerName)
                .font(.system(size: 13, weight: isLocal ? .heavy : .regular))
                .foregroundColor(isLocal ? Color.gameGold : .white.opacity(0.7))
                .lineLimit(1)
            Spacer()
            Text(vm.currentMode.gcLeaderboard.formatScore(entry.score))
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(isLocal ? Color.gameGold : .white.opacity(0.6))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isLocal ? Color.gameGold.opacity(0.08) : Color.clear)
        .cornerRadius(6)
    }

    private func statRow(label: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.system(size: 12)).foregroundColor(.white.opacity(0.5)).tracking(2)
            Text(value)
                .font(.system(size: 48, weight: .black))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: – Helpers
    private var titleText: String {
        switch vm.currentMode {
        case .normal:  return "時間到！"
        case .daily:   return "挑戰完成！"
        case .endless: return vm.lives <= 0 ? "遊戲結束！" : "厲害！"
        }
    }

    private var replayLabel: String {
        if vm.currentMode == .daily {
            return vm.canPlayDaily ? "再挑戰" : "今日挑戰已結束"
        }
        return "再玩一次"
    }

    private var replayDisabled: Bool {
        vm.currentMode == .daily && !vm.canPlayDaily
    }
}

struct AccuracyBar: View {
    let accuracy: Int
    @State private var filled = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: [Color.accent, Color.gameGold],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: filled ? geo.size.width * CGFloat(accuracy) / 100 : 0)
                    .animation(.easeOut(duration: 1.0).delay(0.15), value: filled)
            }
        }
        .frame(height: 5)
        .onAppear { filled = true }
    }
}
