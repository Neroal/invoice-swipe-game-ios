import SwiftUI

struct GameView: View {
    @EnvironmentObject var vm: GameViewModel
    private let cardW: CGFloat = min(300, UIScreen.main.bounds.width * 0.88)
    private let cardH: CGFloat = 200

    var body: some View {
        ZStack {
            Color(hex: "0f0f1a").ignoresSafeArea()

            VStack(spacing: 0) {
                prizePanel
                feedbackBar
                cardArea
            }
        }
    }

    // MARK: – Feedback bar（prize panel 下方固定區塊）
    private var feedbackBar: some View {
        ZStack {
            // mini badge（小獎提示）
            if vm.showMiniBadge {
                Text(vm.miniBadgeText)
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color(hex: "f5a623"))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 6)
                    .background(Color(hex: "f5a623").opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: "f5a623").opacity(0.35), lineWidth: 1))
                    .cornerRadius(20)
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
            }

            // 答對 / 答錯 提示
            if vm.showFeedback && !vm.showMiniBadge {
                Text(vm.feedbackText)
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(vm.feedbackCorrect ? Color(hex: "2ecc71") : Color(hex: "e74c3c"))
                    .tracking(2)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .frame(height: 38)
        .animation(.spring(dampingFraction: 0.65), value: vm.showMiniBadge)
        .animation(.spring(dampingFraction: 0.65), value: vm.showFeedback)
    }

    // MARK: – Prize panel
    private var prizePanel: some View {
        VStack(spacing: 10) {
            HStack {
                Text(vm.currentPeriodLabel)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))
                    .tracking(1)
                Spacer()
                hudRow
            }

            HStack(spacing: 6) {
                prizePill(name: "特別獎", num: vm.prizes.special, highlight: false)
                prizePill(name: "特獎",   num: vm.prizes.grand,   highlight: false)
                prizePill(name: "頭獎",   num: vm.prizes.first,   highlight: true)
            }

            Text("末 3 碼  \(vm.prizes.sixthSuffix)  中六獎")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.white.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "1a1a2e"))
        .overlay(Rectangle().frame(height: 1).foregroundColor(.white.opacity(0.06)), alignment: .bottom)
    }

    @ViewBuilder
    private var hudRow: some View {
        if vm.currentMode == .endless {
            HStack(spacing: 6) {
                livesView
                hudChip(label: "連續", value: "\(vm.currentStreak)", color: Color(hex: "a78bfa"))
                hudChip(label: "張數", value: "\(vm.totalCount)",    color: .white)
            }
        } else {
            HStack(spacing: 6) {
                hudChip(label: "張數", value: "\(vm.totalCount)",   color: .white)
                hudChip(label: "時間", value: "\(vm.timeLeft)",
                        color: vm.timeLeft <= 5 ? Color(hex: "e94560") : Color(hex: "f5a623"))
                hudChip(label: "答對", value: "\(vm.correctCount)", color: Color(hex: "2ecc71"))
            }
        }
    }

    private var livesView: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Image(systemName: i < vm.lives ? "heart.fill" : "heart")
                    .font(.system(size: 14))
                    .foregroundColor(i < vm.lives ? Color(hex: "e74c3c") : Color.white.opacity(0.2))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(6)
    }

    // MARK: – Card area
    private var cardArea: some View {
        ZStack {
            // Side indicators
            HStack {
                sideIndicator(isRight: false)
                Spacer()
                sideIndicator(isRight: true)
            }
            .padding(.horizontal, 12)

            // Card stack
            ZStack {
                ForEach(Array(vm.cards.prefix(3).enumerated().reversed()), id: \.element.id) { idx, card in
                    let isTop = idx == 0
                    cardView(card: card, index: idx, isTop: isTop)
                }
                // Flying card overlay：飛出動畫獨立執行，不卡輸入
                if let flying = vm.flyingCard, let dir = vm.flyingDir {
                    FlyingCardView(
                        card:        flying,
                        direction:   dir,
                        startOffset: vm.flyingStartOffset,
                        cardW:       cardW,
                        cardH:       cardH
                    )
                }
            }
            .frame(width: cardW, height: cardH)

            // Action buttons
            actionButtons
                .padding(.horizontal, 20)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 20)
        }
    }

    private func cardView(card: Invoice, index: Int, isTop: Bool) -> some View {
        let scaleDown = 1.0 - Double(index) * 0.05
        let pushDown  = CGFloat(index) * 9.0

        return InvoiceCardView(
            invoice: card,
            dragOffset: isTop ? vm.dragOffset : .zero,
            isTop: isTop
        )
        .frame(width: cardW, height: cardH)
        .scaleEffect(isTop ? 1.0 : scaleDown)
        .offset(y: isTop ? 0 : pushDown)
        .brightness(isTop ? 0 : -0.18 * Double(index))
        .offset(isTop ? vm.dragOffset : .zero)
        .rotationEffect(.degrees(isTop ? Double(vm.dragOffset.width) * 0.06 : 0))
        // FlyingCardView 接管後立刻隱藏 top card，避免重疊
        .opacity(isTop && vm.flyingCard != nil ? 0 : 1)
        .animation(.interactiveSpring(), value: vm.dragOffset)
        .zIndex(Double(10 - index))
        .gesture(isTop ? dragGesture : nil)
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
        .foregroundColor(isRight ? Color(hex: "2ecc71") : Color(hex: "e74c3c"))
        .opacity(triggered ? 1 : 0.18)
        .animation(.easeOut(duration: 0.15), value: triggered)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button { vm.processSwipe(.left) } label: {
                Text("✕ 未中獎")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color(hex: "e74c3c"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "e74c3c").opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 50)
                        .stroke(Color(hex: "e74c3c").opacity(0.35), lineWidth: 1.5))
                    .cornerRadius(50)
            }
            Button { vm.processSwipe(.right) } label: {
                Text("中獎 ✓")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(1)
                    .foregroundColor(Color(hex: "2ecc71"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(hex: "2ecc71").opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 50)
                        .stroke(Color(hex: "2ecc71").opacity(0.35), lineWidth: 1.5))
                    .cornerRadius(50)
            }
        }
    }

    // MARK: – Helpers
    private func prizePill(name: String, num: String, highlight: Bool) -> some View {
        VStack(spacing: 3) {
            Text(name).font(.system(size: 11)).foregroundColor(.white.opacity(0.5)).tracking(1)
            Text(num)
                .font(.system(size: 17, weight: .black, design: .monospaced))
                .foregroundColor(highlight ? Color(hex: "ff6b6b") : .white)
                .tracking(1.5)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 8).padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(highlight ? Color(hex: "cc2200").opacity(0.08) : Color.white.opacity(0.04))
        .overlay(RoundedRectangle(cornerRadius: 6)
            .stroke(highlight ? Color(hex: "cc2200").opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1))
        .cornerRadius(6)
    }

    private func hudChip(label: String, value: String, color: Color) -> some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 9)).foregroundColor(.white.opacity(0.35)).tracking(2)
            Text(value)
                .font(.system(size: 22, weight: .black, design: .monospaced))
                .foregroundColor(color)
        }
        .padding(.horizontal, 10).padding(.vertical, 4)
        .background(Color.white.opacity(0.06))
        .cornerRadius(6)
    }
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
                    ? UIScreen.main.bounds.width * 1.5
                    : -UIScreen.main.bounds.width * 1.5

                withAnimation(.easeOut(duration: 0.30)) {
                    offset   = CGSize(width: targetX, height: startOffset.height)
                    rotation = direction == .right ? 22 : -22
                }
            }
    }
}
