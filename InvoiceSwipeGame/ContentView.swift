import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ZStack {
            // Main screens
            Group {
                switch vm.phase {
                case .start:
                    StartView()
                        .transition(.opacity)
                case .countdown, .playing:
                    GameView()
                        .transition(.opacity)
                case .result:
                    ResultView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.25), value: vm.phase)

            // Countdown overlay
            if vm.showCountdown {
                CountdownView()
                    .transition(.opacity)
                    .zIndex(10)
            }

            // Screen flash (brief, non-blocking)
            if vm.bigWinFlash {
                bigWinFlashColor
                    .opacity(0.28)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
                    .zIndex(14)
            }

            // Burst particles for special / grand
            if vm.showBigWin, let t = vm.bigWinTier, t == .special || t == .grand {
                ParticleBurstView(tier: t)
                    .transition(.opacity)
                    .zIndex(15)
            }

            // Non-blocking fly-in banner (slides from trailing edge, fades out)
            if vm.showBigWin, let tier = vm.bigWinTier {
                BigWinOverlayView(tier: tier)
                    .id(vm.bigWinID)   // 每次中獎 id 自增，強制 re-insert → slide-in 動畫必定觸發
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal:   .opacity))
                    .zIndex(18)
            }

            // Tutorial
            if vm.showTutorial {
                TutorialView()
                    .transition(.opacity)
                    .zIndex(50)
            }

            // Settings
            if vm.showSettings {
                SettingsView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(40)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: vm.showCountdown)
        .animation(.easeOut(duration: 0.12),  value: vm.bigWinFlash)
        .animation(.easeInOut(duration: 0.2), value: vm.showTutorial)
        .animation(.spring(dampingFraction: 0.8), value: vm.showSettings)
    }

    private var bigWinFlashColor: Color {
        switch vm.bigWinTier {
        case .special: return Color(hex: "ff4444")
        case .grand:   return Color(hex: "ffaa00")
        default:       return Color(hex: "00ffaa")
        }
    }
}
