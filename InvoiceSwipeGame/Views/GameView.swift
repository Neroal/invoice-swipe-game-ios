import SwiftUI

struct GameView: View {
    @EnvironmentObject var vm: GameViewModel
    var body: some View {
        GeometryReader { geo in
            let isIPad = geo.size.width > 700
            let cardW = isIPad ? min(geo.size.width * 0.75, 480) : geo.size.width * 0.75
            // 動態計算卡片高度：填滿 HUD ↔ 按鈕之間的空間，上下各留 50pt
            let burnH: CGFloat = vm.currentMode == .endless ? 12 : 0
            let reserved: CGFloat = 145 + 38 + burnH + 75 + 100   // prizePanel + feedbackBar + burnBar + buttons + gaps
            let cardH = max(250, geo.size.height - reserved)

            ZStack {
                Color.gameBg.ignoresSafeArea()

                VStack(spacing: 0) {
                    prizePanel
                    feedbackBar
                    if vm.currentMode == .endless {
                        burnTimerBar
                    }
                    Color.clear.frame(height: 50)
                    invoiceArea(cardW: cardW, cardH: cardH, screenWidth: geo.size.width)
                    Color.clear.frame(height: 50)
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                }

                // 邊緣隨連擊升溫發光，全模式
                streakEdgeGlow
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: – Feedback bar（prize panel 下方固定區塊）
    private var feedbackBar: some View {
        ZStack {
            // 答對 / 答錯 提示（中獎已走 banner，這裡只顯示非中獎結果）
            if vm.showFeedback {
                Text(vm.feedbackText)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(vm.feedbackColor)
                    .tracking(2)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .frame(height: 38)
        .animation(.spring(dampingFraction: 0.65), value: vm.showFeedback)
    }

    // MARK: – Prize panel
    private var prizePanel: some View {
        VStack(spacing: 7) {
            HStack {
                Spacer()
                hudRow
                Spacer()
            }

            // 特別獎
            prizeRowSingle(label: "特別獎", number: vm.prizes.special)

            // 特獎
            prizeRowSingle(label: "特獎", number: vm.prizes.grand)

            // 頭獎 × 3（末 3 碼紅字）
            prizeRowTriple(numbers: vm.prizes.firsts)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.panelBg)
        .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.06)), alignment: .bottom)
    }

    private func prizeRowSingle(label: String, number: String) -> some View {
        ZStack {
            Text(number)
                .font(.system(size: 18, weight: .black, design: .monospaced))
                .foregroundColor(.white)
                .tracking(1)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .center)
            HStack {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1)
                Spacer()
            }
        }
    }

    private func prizeRowTriple(numbers: [String]) -> some View {
        HStack(spacing: 0) {
            Text("頭獎")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.45))
                .tracking(1)
                .frame(width: 46, alignment: .leading)
            HStack(spacing: 4) {
                ForEach(Array(numbers.enumerated()), id: \.offset) { _, number in
                    coloredFirstNumber(number)
                        .frame(maxWidth: .infinity)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
            }
        }
    }

    private func coloredFirstNumber(_ number: String) -> Text {
        let prefix = String(number.prefix(5))
        let suffix = String(number.suffix(3))
        return (
            Text(prefix).foregroundColor(.white) +
            Text(suffix).foregroundColor(Color(hex: "ff6b6b"))
        )
        .font(.system(size: 16, weight: .black, design: .monospaced))
        .tracking(0.5)
    }

    @ViewBuilder
    private var hudRow: some View {
        if vm.currentMode == .endless {
            HStack(spacing: 6) {
                livesView
                comboChip(streak: vm.currentStreak)
            }
        } else {
            timerPrizeChip
        }
    }

    private var timerPrizeChip: some View {
        HStack(spacing: 0) {
            VStack(spacing: 1) {
                Text("時間")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(2)
                Text("\(vm.timeLeft)")
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(vm.timeLeft <= 5 ? Color.accent : Color.gameGold)
            }
            .frame(width: 68)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 28)

            VStack(spacing: 1) {
                Text("中獎")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.35))
                    .tracking(2)
                Text(vm.hudPrizeString)
                    .font(.system(size: 22, weight: .black, design: .monospaced))
                    .foregroundColor(Color.successGreen)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(6)
        .frame(width: 240)
    }

    private var livesView: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < vm.lives ? "heart.fill" : "heart")
                    .font(.system(size: 14))
                    .foregroundColor(i < vm.lives ? Color.errorRed : Color.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(6)
    }

    // MARK: – Invoice area
    private func invoiceArea(cardW: CGFloat, cardH: CGFloat, screenWidth: CGFloat) -> some View {
        ZStack {
            HStack {
                sideIndicator(isRight: false)
                Spacer()
                sideIndicator(isRight: true)
            }
            .padding(.horizontal, 12)

            if let card = vm.cards.first {
                InvoiceCardView(invoice: card, dragOffset: vm.dragOffset, isTop: true)
                    .frame(width: cardW, height: cardH)
                    .offset(vm.dragOffset)
                    .rotationEffect(.degrees(Double(vm.dragOffset.width) * 0.04))
                    .opacity(card.id == vm.flyingCard?.id ? 0 : 1)
                    .animation(.interactiveSpring(), value: vm.dragOffset)
                    .gesture(dragGesture)
            }

            if let flying = vm.flyingCard, let dir = vm.flyingDir {
                FlyingCardView(
                    card:        flying,
                    direction:   dir,
                    startOffset: vm.flyingStartOffset,
                    cardW:       cardW,
                    cardH:       cardH,
                    screenWidth: screenWidth
                )
            }
        }
        .frame(height: cardH)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { val in
                guard !vm.isAnimating else { return }
                vm.dragOffset = val.translation
            }
            .onEnded { val in
                guard !vm.isAnimating else { return }
                let w = val.translation.width
                if      w >  90 { vm.processSwipe(.right) }
                else if w < -90 { vm.processSwipe(.left)  }
                else {
                    withAnimation(.spring()) { vm.dragOffset = .zero }
                }
            }
    }

    private func sideIndicator(isRight: Bool) -> some View {
        let triggered = isRight
            ? vm.dragOffset.width > 30
            : vm.dragOffset.width < -30
        return VStack(spacing: 4) {
            Text(isRight ? "→" : "←")
                .font(.system(size: 24))
            Text(isRight ? "中獎" : "未中")
                .font(.caption2).fontWeight(.bold)
                .tracking(1)
        }
        .foregroundColor(isRight ? Color.successGreen : Color.errorRed)
        .opacity(triggered ? 1 : 0.18)
        .animation(.easeOut(duration: 0.15), value: triggered)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { vm.processSwipe(.left) } label: {
                Text("✕ 未中獎")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color.errorRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.errorRed.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.errorRed.opacity(0.35), lineWidth: 1.5))
                    .cornerRadius(50)
            }
            Button { vm.processSwipe(.right) } label: {
                Text("中獎 ✓")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color.successGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.successGreen.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.successGreen.opacity(0.35), lineWidth: 1.5))
                    .cornerRadius(50)
            }
        }
        .frame(maxWidth: 520)
    }

    // MARK: – Burn timer bar (Endless only)

    private var burnTimerBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.12))
                let ratio = vm.burnTimerFull > 0 ? vm.burnTimeLeft / vm.burnTimerFull : 0
                let clamped = max(0.0, min(1.0, ratio))
                RoundedRectangle(cornerRadius: 2)
                    .fill(burnBarColor(ratio: ratio))
                    .frame(width: geo.size.width * CGFloat(clamped))
                    .animation(.linear(duration: 0.05), value: vm.burnTimeLeft)
            }
        }
        .frame(height: 4)
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    private func burnBarColor(ratio: Double) -> Color {
        if ratio > 0.5  { return Color.successGreen }
        if ratio > 0.25 { return Color.gameGold }
        return Color.accent
    }

    // MARK: – Combo UI helpers

    private func comboChip(streak: Int) -> some View {
        let color: Color = {
            switch streak {
            case 0..<5:   return Color.comboPurple   // phase 1
            case 5..<10:  return Color.gameGold   // phase 2
            case 10..<20: return Color.comboDeepOrange   // phase 3
            default:      return Color.comboBrightRed   // phase 4
            }
        }()
        return VStack(spacing: 1) {
            Text("連續")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.35))
                .tracking(2)
            Text("\(streak)")
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundColor(color)
                .shadow(color: color.opacity(streak >= 5 ? 0.8 : 0), radius: 8)
                .lineLimit(1)
                .fixedSize()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(6)
        .fixedSize()
        .animation(.spring(dampingFraction: 0.5), value: streak)
    }

    private var streakEdgeGlow: some View {
        let streak = vm.currentStreak
        let (glowColor, glowOpacity): (Color, Double) = {
            switch streak {
            case 0..<5:   return (Color.gameGold, 0.0)    // phase 1: 無發光
            case 5..<10:  return (Color.gameGold, 0.40)   // phase 2
            case 10..<20: return (Color.comboDeepOrange, 0.65)   // phase 3
            default:      return (Color.comboBrightRed, 0.85)   // phase 4
            }
        }()
        return Rectangle()
            .stroke(glowColor, lineWidth: 30)
            .blur(radius: 18)
            .opacity(glowOpacity)
            .animation(.easeOut(duration: 0.35), value: streak)
    }

    // MARK: – Helpers
}

// MARK: – Flying card overlay
/// 飛出動畫獨立執行，與輸入鎖解耦。
/// 卡片從 startOffset 位置出發，以 easeOut(0.30) 飛離螢幕。
private struct FlyingCardView: View {
    let card:        Invoice
    let direction:   SwipeDirection
    let startOffset: CGSize
    let cardW:       CGFloat
    let cardH:       CGFloat
    let screenWidth: CGFloat

    @State private var offset:   CGSize = .zero
    @State private var rotation: Double = 0

    /// 傳給 InvoiceCardView 的 dragOffset，讓中獎/未中獎 overlay 保持全開
    private var colorOffset: CGSize {
        direction == .right
            ? CGSize(width: 200, height: 0)
            : CGSize(width: -200, height: 0)
    }

    var body: some View {
        InvoiceCardView(invoice: card, dragOffset: colorOffset, isTop: true)
            .frame(width: cardW, height: cardH)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                // 從 startOffset 出發
                offset   = startOffset
                rotation = Double(startOffset.width) * 0.06

                let targetX = direction == .right
                    ? screenWidth * 1.5
                    : -screenWidth * 1.5

                withAnimation(.easeOut(duration: 0.30)) {
                    offset   = CGSize(width: targetX, height: startOffset.height)
                    rotation = direction == .right ? 22 : -22
                }
            }
    }
}
