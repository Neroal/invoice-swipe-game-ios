import SwiftUI

// 隱私政策網址 — 部署至 GitHub Pages (docs/ 資料夾)
private let privacyPolicyURL = URL(string: "https://neroal.github.io/invoice-swipe-game-ios/")!

struct SettingsView: View {
    @EnvironmentObject var vm: GameViewModel
    @ObservedObject private var store = StoreKitManager.shared
    @ObservedObject private var gc    = GameCenterManager.shared

    @State private var soundOn: Bool = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool ?? true
    @State private var showRestoreAlert  = false
    @State private var restoreAlertMsg   = ""
    @State private var showGCAlert       = false
    @State private var showInstructions  = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.55).ignoresSafeArea()
                .onTapGesture { vm.showSettings = false }

            VStack(spacing: 0) {
                // Handle
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)
                    .padding(.bottom, 18)

                Text("設定")
                    .font(.system(size: 15, weight: .black))
                    .tracking(4)
                    .foregroundColor(.white.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)

                // ── 音效 ──────────────────────────────────────
                settingRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("音效").foregroundColor(.white.opacity(0.85))
                        Text("滑動、回饋、中獎音效")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                    }
                } trailing: {
                    Toggle("", isOn: $soundOn)
                        .labelsHidden()
                        .tint(Color.successGreen)
                        .onChange(of: soundOn) { val in
                            vm.sound.isEnabled = val
                        }
                }

                // ── Game Center 排行榜 ────────────────────────
                settingRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("排行榜").foregroundColor(.white.opacity(0.85))
                        Text(gc.isAuthenticated ? "Game Center 已連線" : "未登入 Game Center")
                            .font(.caption2)
                            .foregroundColor(gc.isAuthenticated
                                ? Color.successGreen.opacity(0.7)
                                : .white.opacity(0.3))
                    }
                } trailing: {
                    if gc.isAuthenticated {
                        EmptyView()
                    } else {
                        Button("登入") {
                            GameCenterManager.shared.authenticate()
                            // 延遲偵測：若 iOS 沒有彈出視窗（已拒絕過），引導去系統設定
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                if !GameCenterManager.shared.isAuthenticated &&
                                   !GameCenterManager.shared.showAuthSheet {
                                    showGCAlert = true
                                }
                            }
                        }
                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .cornerRadius(7)
                        .hapticTap()
                    }
                }

                // ── 遊戲說明 ──────────────────────────────────
                settingRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("遊戲說明").foregroundColor(.white.opacity(0.85))
                        Text("各模式規則與獎項說明")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                    }
                } trailing: {
                    Button("查看") { showInstructions = true }
                        .font(.system(size: 13)).foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Color.white.opacity(0.07))
                        .overlay(RoundedRectangle(cornerRadius: 7)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1))
                        .cornerRadius(7)
                        .hapticTap()
                }

                // ── 隱私權政策 ────────────────────────────────
                settingRow {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("隱私權政策").foregroundColor(.white.opacity(0.85))
                        Text("排行榜與資料使用說明")
                            .font(.system(size: 12)).foregroundColor(.white.opacity(0.4))
                    }
                } trailing: {
                    Link(destination: privacyPolicyURL) {
                        Text("查看")
                            .font(.caption).foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 14).padding(.vertical, 7)
                            .background(Color.white.opacity(0.07))
                            .overlay(RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1))
                            .cornerRadius(7)
                    }
                }

                // ── 咖啡贊助 IAP ──────────────────────────────
                coffeeSection

                #if DEBUG
                Button("重置新手教學（測試用）") {
                    UserDefaults.standard.removeObject(forKey: "tutorial_seen_normal")
                    UserDefaults.standard.removeObject(forKey: "tutorial_seen_daily")
                    UserDefaults.standard.removeObject(forKey: "tutorial_seen_endless")
                }
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.2))
                .padding(.top, 8)
                #endif

                Spacer().frame(height: 40)
            }
            .background(Color.panelBg)
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .overlay(Rectangle().frame(height: 1)
                .foregroundColor(.white.opacity(0.08)), alignment: .top)
        }
        .ignoresSafeArea(edges: .bottom)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .sheet(isPresented: $showInstructions) { InstructionsView() }
        .alert("恢復購買", isPresented: $showRestoreAlert) {
            Button("確定", role: .cancel) {}
        } message: {
            Text(restoreAlertMsg)
        }
        .alert("請登入 Game Center", isPresented: $showGCAlert) {
            Button("前往設定") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("請到「設定 → Game Center」登入 Apple ID，即可使用排行榜功能。")
        }
    }

    // MARK: – Coffee section

    @ViewBuilder
    private var coffeeSection: some View {
        if store.isPurchased {
            // 已購買
            HStack(spacing: 8) {
                Text("感謝支持，你好棒！")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color.gameGold)
            }
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)

        } else {
            VStack(spacing: 8) {
                // 購買按鈕
                Button {
                    Task { await store.purchase() }
                } label: {
                    ZStack {
                        if store.isLoading {
                            ProgressView().tint(Color.gameGold)
                        } else {
                            HStack(spacing: 6) {
                                Text("請開發者喝咖啡")
                                if let price = store.coffeeProduct?.displayPrice {
                                    Text("·  \(price)")
                                        .font(.system(size: 12))
                                        .opacity(0.6)
                                }
                            }
                            .font(.system(size: 13, weight: .bold))
                            .tracking(1)
                            .foregroundColor(Color.gameGold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gameGold.opacity(0.1))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gameGold.opacity(0.3), lineWidth: 1))
                    .cornerRadius(10)
                }
                .disabled(store.isLoading)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .hapticTap(style: .medium)

                // 錯誤訊息
                if let msg = store.errorMessage {
                    Text(msg)
                        .font(.system(size: 12))
                        .foregroundColor(Color.errorRed)
                        .padding(.horizontal, 24)
                }

                // 恢復購買
                Button {
                    Task {
                        await store.restorePurchases()
                        restoreAlertMsg = store.isPurchased
                            ? "已成功恢復購買，感謝你的支持"
                            : "找不到購買記錄"
                        showRestoreAlert = true
                    }
                } label: {
                    Text("恢復購買")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.3))
                        .padding(.bottom, 4)
                }
                .hapticTap()
            }
        }
    }

    // MARK: – Helpers

    private func settingRow<L: View, T: View>(@ViewBuilder leading: () -> L,
                                               @ViewBuilder trailing: () -> T) -> some View {
        HStack {
            leading().font(.system(size: 14))
            Spacer()
            trailing()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .overlay(Rectangle().frame(height: 1)
            .foregroundColor(.white.opacity(0.06)), alignment: .top)
    }
}

// MARK: – Instructions

struct InstructionsView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.gameBg.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 12) {
                        instSection("獎項說明", rows: [
                            ("特別獎", "全 8 碼", "NT$10,000,000"),
                            ("特獎",   "全 8 碼", "NT$2,000,000"),
                            ("頭獎",   "全 8 碼", "NT$200,000"),
                            ("二獎",   "後 7 碼", "NT$40,000"),
                            ("三獎",   "後 6 碼", "NT$10,000"),
                            ("四獎",   "後 5 碼", "NT$4,000"),
                            ("五獎",   "後 4 碼", "NT$1,000"),
                            ("六獎",   "後 3 碼", "NT$200"),
                        ])
                        instSection("遊戲模式", rows: [
                            ("一般模式", "30秒計時  連擊提升大獎機率", "總獎金排名"),
                            ("每日挑戰", "全球同一題  獎金 × 準確率", "每日重置排行"),
                            ("無限模式", "倒數計時  連擊越高壓力越大", "最長連擊排名"),
                        ])
                        instSection("操作", rows: [
                            ("右滑 / →", "中獎",   ""),
                            ("左滑 / ←", "未中獎", ""),
                        ])
                    }
                    .padding(20)
                }
            }
            .navigationTitle("遊戲說明")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .navigationBarTrailing) {
                Button("關閉") { dismiss() }.foregroundColor(Color.accent)
            }}
        }
        .preferredColorScheme(.dark)
    }

    private func instSection(_ title: String,
                              rows: [(String, String, String)]) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.white.opacity(0.06))
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0).font(.system(size: 13)).foregroundColor(.white.opacity(0.75))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(row.1).font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                        if !row.2.isEmpty {
                            Text(row.2).font(.system(size: 12)).foregroundColor(Color.gameGold)
                        }
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
                .overlay(Rectangle().frame(height: 1)
                    .foregroundColor(.white.opacity(0.05)), alignment: .top)
            }
        }
        .background(Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(12)
    }
}
