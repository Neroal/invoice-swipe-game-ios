import SwiftUI

struct InvoiceCardView: View {
    let invoice: Invoice
    let dragOffset: CGSize
    let isTop: Bool

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
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.cardBg)

            VStack(spacing: 0) {
                // 紅色標題列
                Text("統 一 發 票")
                    .font(.system(size: 14, weight: .bold))
                    .tracking(2)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.stampRed)

                // 發票號碼（最大最顯眼，垂直方向撐滿剩餘空間）
                VStack(spacing: 4) {
                    Spacer(minLength: 14)
                    Text(invoice.displayNumber)
                        .font(.system(size: 32, weight: .black, design: .monospaced))
                        .tracking(2)
                        .foregroundColor(Color.panelBg)
                        .minimumScaleFactor(0.4)
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                    Spacer(minLength: 14)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                ReceiptDashedLine()

                // 賣方資訊
                VStack(alignment: .leading, spacing: 5) {
                    infoRow(label: "賣方名稱", value: invoice.seller)
                    infoRow(label: "統一編號", value: invoice.taxId)
                    infoRow(label: "品名", value: invoice.itemName)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)

                ReceiptDashedLine()

                // 金額明細
                VStack(spacing: 4) {
                    amountRow(label: "小計", amount: invoice.subtotal)
                    amountRow(label: "稅額(5%)", amount: invoice.tax)
                    Rectangle()
                        .fill(Color(hex: "dddddd"))
                        .frame(height: 1)
                        .padding(.vertical, 2)
                    amountRow(label: "總計", amount: invoice.amount, bold: true)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)

                ReceiptDashedLine()

                // 裝飾性條碼
                ReceiptBarcodeView()
                    .frame(height: 24)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 9)

            }

            if rightOpacity > 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.successGreen.opacity(rightOpacity))
                Text("中獎！")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                    .opacity(rightOpacity)
            }
            if leftOpacity > 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.errorRed.opacity(leftOpacity))
                Text("未中獎")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(.white)
                    .opacity(leftOpacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.55), radius: 20, x: 0, y: 10)
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "999999"))
                .frame(width: 52, alignment: .leading)
            Text(value)
                .font(.system(size: 9, weight: .medium))
                .foregroundColor(Color(hex: "333333"))
                .lineLimit(1)
            Spacer()
        }
    }

    private func amountRow(label: String, amount: Int, bold: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 9))
                .foregroundColor(Color(hex: "888888"))
            Spacer()
            Text("NT$\(amount.formatted())")
                .font(bold
                    ? .system(size: 11, weight: .bold, design: .monospaced)
                    : .system(size: 9, design: .monospaced))
                .foregroundColor(bold ? Color.panelBg : Color(hex: "555555"))
        }
    }
}

private struct ReceiptDashedLine: View {
    var body: some View {
        GeometryReader { geo in
            Path { p in
                p.move(to: CGPoint(x: 8, y: 0.5))
                p.addLine(to: CGPoint(x: geo.size.width - 8, y: 0.5))
            }
            .stroke(Color(hex: "cccccc"), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
        }
        .frame(height: 1)
    }
}

private struct ReceiptBarcodeView: View {
    private static let widths: [CGFloat] = [
        2, 1, 3, 1, 2, 1, 1, 2, 3, 1,
        2, 1, 1, 3, 1, 2, 1, 1, 3, 2,
        1, 1, 2, 3, 1, 1, 4, 1, 2, 1,
        1, 3, 1, 2, 1, 1, 2, 3, 1, 2
    ]
    private static let totalUnits: CGFloat = widths.reduce(0, +)

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / Self.totalUnits
            HStack(spacing: 0) {
                ForEach(Array(Self.widths.enumerated()), id: \.offset) { idx, w in
                    Rectangle()
                        .fill(idx % 2 == 0 ? Color.black.opacity(0.7) : Color.clear)
                        .frame(width: w * scale)
                }
            }
        }
    }
}
