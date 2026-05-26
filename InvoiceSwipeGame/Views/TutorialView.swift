import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var vm: GameViewModel
    /// 從設定頁進來時傳入，只關閉教學而不開始遊戲
    var isPreview: Bool = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.3))

            VStack(spacing: 22) {
                VStack(spacing: 4) {
                    Text("如何遊戲")
                        .font(.system(size: 30, weight: .black))
                        .foregroundColor(.white)
                        .tracking(5)
                    Text("HOW TO PLAY")
                        .font(.system(size: 11)).foregroundColor(.white.opacity(0.35)).tracking(3)
                }

                VStack(spacing: 12) {
                    stepRow(num: "1",
                            text: "畫面**上方**顯示本期中獎號碼\n記住頭獎號碼的末幾碼")
                    stepRow(num: "2",
                            text: "快速對照下方**發票號碼**\n判斷是否符合中獎條件")
                    stepRow(num: "3",
                            text: "**右滑** = 中獎　　**左滑** = 未中\n也可點畫面下方按鈕")
                }
                .padding(.horizontal, 24)

                Button {
                    if isPreview {
                        vm.showTutorial  = false
                        vm.showSettings  = true
                    } else {
                        vm.dismissTutorial()
                    }
                } label: {
                    Text(isPreview ? "關閉" : "我知道了，開始！")
                        .font(.system(size: 16, weight: .black))
                        .tracking(3)
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 16)
                        .background(Color(hex: "e94560"))
                        .cornerRadius(10)
                        .shadow(color: Color(hex: "a0001e"), radius: 0, x: 0, y: 4)
                }
                .hapticTap(style: .medium)
                .padding(.horizontal, 24)
            }
        }
        .transition(.opacity)
    }

    private func stepRow(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(num)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color(hex: "e94560"))
                .clipShape(Circle())

            Text(LocalizedStringKey(text))
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 4)
        }
        .padding(14)
        .background(Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(12)
    }
}
