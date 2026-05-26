import SwiftUI

struct CountdownView: View {
    @EnvironmentObject var vm: GameViewModel

    var body: some View {
        ZStack {
            Color.black.opacity(0.82).ignoresSafeArea()
                .background(.ultraThinMaterial.opacity(0.4))

            if vm.countdownIsGo {
                Text("GO")
                    .font(.system(size: 130, weight: .black))
                    .foregroundColor(Color(hex: "2ecc71"))
                    .shadow(color: Color(hex: "2ecc71").opacity(0.7), radius: 30)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                    .id("go")
            } else {
                Text("\(vm.countdownValue)")
                    .font(.system(size: 200, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: Color(hex: "f5a623").opacity(0.6), radius: 40)
                    .transition(.scale(scale: 1.4).combined(with: .opacity))
                    .id("num-\(vm.countdownValue)")
            }
        }
        .animation(.spring(dampingFraction: 0.7), value: vm.countdownValue)
        .animation(.spring(dampingFraction: 0.7), value: vm.countdownIsGo)
    }
}
