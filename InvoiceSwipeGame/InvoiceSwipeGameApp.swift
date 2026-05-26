import SwiftUI

@main
struct InvoiceSwipeGameApp: App {
    @StateObject private var viewModel = GameViewModel()
    @StateObject private var gc        = GameCenterManager.shared
    @StateObject private var store     = StoreKitManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
                .environmentObject(gc)
                .environmentObject(store)
                .preferredColorScheme(.dark)
                // Game Center 登入畫面（首次啟動 / 未登入時出現）
                .sheet(isPresented: $gc.showAuthSheet) {
                    if let vc = gc.authVC {
                        GameCenterAuthView(viewController: vc)
                            .ignoresSafeArea()
                    }
                }
                .onAppear {
                    GameCenterManager.shared.authenticate()
                }
        }
    }
}
