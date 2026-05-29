import SwiftUI

struct TutorialView: View {
    @EnvironmentObject var vm: GameViewModel

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
                    Text(vm.currentMode.displayName.uppercased())
                        .font(.system(size: 11)).foregroundColor(Color.accent.opacity(0.8)).tracking(3)
                }

                VStack(spacing: 12) {
                    ForEach(Array(modeSteps.enumerated()), id: \.offset) { idx, step in
                        stepRow(num: "\(idx + 1)", text: step)
                    }
                }
                .padding(.horizontal, 24)

                Button {
                    vm.dismissTutorial()
                } label: {
                    Text("我知道了，開始！")
                        .font(.system(size: 16, weight: .black))
                        .tracking(3)
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 16)
                        .background(Color.accent)
                        .cornerRadius(10)
                        .shadow(color: Color(hex: "a0001e"), radius: 0, x: 0, y: 4)
                }
                .hapticTap(style: .medium)
                .padding(.horizontal, 24)
            }
        }
        .transition(.opacity)
    }

    private var commonSteps: [String] {
        [
            "畫面**上方**顯示本期中獎號碼\n記住頭獎號碼的末幾碼",
            "快速對照下方**發票號碼**\n判斷是否符合中獎條件",
            "**右滑** = 中獎　　**左滑** = 未中\n也可點畫面下方按鈕",
        ]
    }

    private var modeSteps: [String] {
        switch vm.currentMode {
        case .normal:
            return commonSteps + [
                "連續答中發票，**下一張大獎機率**會提升\n多中大獎，得分越高",
            ]
        case .daily:
            return commonSteps + [
                "得分 = **中獎金額 × 準確率**\n精準才能拿高分，衝全球排行",
                "全球同一份題，每天最多 **3 次**\n把握機會，用準確率刷高分",
            ]
        case .endless:
            return commonSteps + [
                "每張發票有**倒數計時**\n連擊越高，時間越短、壓力越大",
                "答錯或超時**扣一條命**，共 3 條命\n排名以**最長連擊**計算",
            ]
        }
    }

    private func stepRow(num: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(num)
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.accent)
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
