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

            // Big win overlay
            if vm.showBigWin {
                BigWinOverlayView()
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(20)
            }

            // Tutorial
            if vm.showTutorial {
                TutorialView(isPreview: vm.showSettings)
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
        .animation(.spring(dampingFraction: 0.75), value: vm.showBigWin)
        .animation(.easeInOut(duration: 0.2), value: vm.showTutorial)
        .animation(.spring(dampingFraction: 0.8), value: vm.showSettings)
    }
}
