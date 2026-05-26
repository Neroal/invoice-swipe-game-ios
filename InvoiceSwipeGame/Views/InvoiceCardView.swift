import SwiftUI

struct InvoiceCardView: View {
    let invoice: Invoice
    let dragOffset: CGSize
    let isTop: Bool

    // Swipe overlays
    private var rightOpacity: Double {
        guard isTop else { return 0 }
        return dragOffset.width > 10 ? Double(min(abs(dragOffset.width) / 100, 1)) * 0.9 : 0
    }
    private var leftOpacity: Double {
        guard isTop else { return 0 }
        return dragOffset.width < -10 ? Double(min(abs(dragOffset.width) / 100, 1)) * 0.9 : 0
    }

    var body: some View {
        ZStack {
            // Card background
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(hex: "fef9ee"))

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("統一發票")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(1)
                    Spacer()
                    Text(invoice.dateString)
                        .font(.system(size: 11))
                        .opacity(0.75)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(Color(hex: "cc2200"))

                // Body
                VStack(alignment: .leading, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("發票號碼")
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "aaaaaa"))
                            .tracking(2)
                        Text(invoice.number)
                            .font(.system(size: 40, weight: .black, design: .monospaced))
                            .tracking(6)
                            .foregroundColor(Color(hex: "1a1a2e"))
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)
                    }
                    Text("\(invoice.seller)　NT$ \(invoice.amount.formatted())")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "999999"))
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Win overlay
            if rightOpacity > 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "2ecc71").opacity(rightOpacity))
                Text("中獎！")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                    .opacity(rightOpacity)
            }

            // Lose overlay
            if leftOpacity > 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "e74c3c").opacity(leftOpacity))
                Text("未中獎")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                    .opacity(leftOpacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.55), radius: 18, x: 0, y: 10)
    }
}
