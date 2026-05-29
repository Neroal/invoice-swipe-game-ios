import SwiftUI

// Non-blocking banner that slides in from the trailing edge
struct BigWinOverlayView: View {
    @EnvironmentObject var vm: GameViewModel

    private var tier: WinTier { vm.bigWinTier ?? .first }

    private var tierAccent: Color {
        switch tier {
        case .special: return Color(hex: "ff4444")
        case .grand:   return Color(hex: "ffaa00")
        case .first:   return Color(hex: "00ffaa")
        case .second:  return Color(hex: "c084fc")
        case .third:   return Color(hex: "60a5fa")
        case .fourth:  return Color(hex: "2dd4bf")
        case .fifth:   return Color(hex: "fbbf24")
        case .sixth:   return Color(hex: "f5a623")
        }
    }

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 6) {
                Text(tier.rawValue)
                    .font(.system(size: 56, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: tierAccent.opacity(0.9), radius: 20)
                Text(tier.amountString)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white.opacity(0.88))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(tierAccent.opacity(0.88))
                    .shadow(color: tierAccent.opacity(0.55), radius: 28)
            )
            Spacer()
        }
        .allowsHitTesting(false)
    }
}

// MARK: – Burst particles: spread radially from card centre, then fade

struct ParticleBurstView: View {
    let tier: WinTier

    private var burstColor: Color {
        switch tier {
        case .special: return Color(hex: "ff4444")
        case .grand:   return Color(hex: "ffaa00")
        default:       return Color(hex: "00ffaa")
        }
    }

    @State private var particles: [BurstParticle] = []

    var body: some View {
        GeometryReader { geo in
            let origin = CGPoint(x: geo.size.width / 2, y: geo.size.height * 0.52)
            ZStack {
                ForEach(particles) { p in
                    BurstParticleView(particle: p, origin: origin)
                }
            }
            .onAppear {
                particles = (0..<36).map { i in
                    BurstParticle(
                        angle:    Double(i) * 10 + Double.random(in: -5...5),
                        distance: CGFloat.random(in: 70...200),
                        size:     CGFloat.random(in: 5...12),
                        duration: Double.random(in: 0.45...0.85),
                        color:    [burstColor, .white, burstColor.opacity(0.7)].randomElement()!
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

private struct BurstParticle: Identifiable {
    let id       = UUID()
    let angle:    Double
    let distance: CGFloat
    let size:     CGFloat
    let duration: Double
    let color:    Color
}

private struct BurstParticleView: View {
    let particle: BurstParticle
    let origin:   CGPoint
    @State private var offset:  CGSize = .zero
    @State private var opacity: Double = 1

    var body: some View {
        Circle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .position(origin)
            .offset(offset)
            .opacity(opacity)
            .onAppear {
                let rad = particle.angle * .pi / 180
                withAnimation(.easeOut(duration: particle.duration)) {
                    offset  = CGSize(width:  CGFloat(cos(rad)) * particle.distance,
                                     height: CGFloat(sin(rad)) * particle.distance)
                    opacity = 0
                }
            }
    }
}
