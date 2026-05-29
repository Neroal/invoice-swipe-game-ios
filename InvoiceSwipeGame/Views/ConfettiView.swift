import SwiftUI

struct ConfettiView: View {
    enum Intensity { case low, medium, high }
    let intensity: Intensity

    private var count: Int {
        switch intensity { case .low: return 30; case .medium: return 60; case .high: return 100 }
    }

    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    ConfettiPieceView(particle: p)
                }
            }
            .onAppear {
                particles = (0..<count).map { _ in
                    ConfettiParticle(
                        x: CGFloat.random(in: 0...geo.size.width),
                        screenHeight: geo.size.height,
                        color: [
                            Color.winSpecial, Color.gameGold,
                            Color.successGreen, Color(hex: "3498db"),
                            Color(hex: "ff66cc"), .white
                        ].randomElement()!,
                        size:  CGFloat.random(in: 6...14),
                        duration: Double.random(in: 1.2...2.8),
                        delay:    Double.random(in: 0...0.6)
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let screenHeight: CGFloat
    let color: Color
    let size: CGFloat
    let duration: Double
    let delay: Double
}

struct ConfettiPieceView: View {
    let particle: ConfettiParticle
    @State private var fallen = false

    var body: some View {
        Rectangle()
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .cornerRadius(1)
            .position(x: particle.x, y: fallen ? particle.screenHeight + 20 : -10)
            .rotationEffect(.degrees(fallen ? 720 : 0))
            .opacity(fallen ? 0 : 1)
            .onAppear {
                withAnimation(.linear(duration: particle.duration)
                    .delay(particle.delay)) {
                    fallen = true
                }
            }
    }
}
