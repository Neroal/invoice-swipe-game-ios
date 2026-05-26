import SwiftUI

struct BigWinOverlayView: View {
    @EnvironmentObject var vm: GameViewModel

    private var tier: WinTier { vm.bigWinTier ?? .first }

    private var bgColors: [Color] {
        switch tier {
        case .special: return [Color(hex: "b40000"), Color(hex: "500000")]
        case .grand:   return [Color(hex: "a05000"), Color(hex: "3c1e00")]
        default:       return [Color(hex: "00503c"), Color(hex: "001e19")]
        }
    }

    private var tierColor: Color {
        switch tier {
        case .special: return .white
        case .grand:   return Color(hex: "ffe066")
        default:       return Color(hex: "a0ffcc")
        }
    }

    private var glowColor: Color {
        switch tier {
        case .special: return Color(hex: "ff4444")
        case .grand:   return Color(hex: "ffaa00")
        default:       return Color(hex: "00ffaa")
        }
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: bgColors,
                center: .center,
                startRadius: 0,
                endRadius: UIScreen.main.bounds.height
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                Text(tier.rawValue)
                    .font(.system(size: 100, weight: .black))
                    .foregroundColor(tierColor)
                    .shadow(color: glowColor.opacity(0.8), radius: 30)
                    .shadow(color: glowColor.opacity(0.4), radius: 60)

                Text(tier.amountString)
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(tierColor.opacity(0.85))
            }
            .transition(.scale(scale: 0.3).combined(with: .opacity))

            // Particle emitter overlay
            if tier == .special || tier == .grand {
                ConfettiView(intensity: tier == .special ? .high : .medium)
            }
        }
        .animation(.spring(dampingFraction: 0.65), value: vm.showBigWin)
    }
}
