import Core
import SwiftUI

struct CartItemRowView: View {
    let item: CartItem

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    private func formatted(_ price: Double) -> String {
        Self.priceFormatter.string(from: NSNumber(value: price))
            ?? String(format: "%.2f", price)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.productName)
                    .font(.headline)
                Text(CoreStrings.cartItemDetailFormat(formatted(item.unitPrice), item.quantity))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(formatted(item.unitPrice * Double(item.quantity)))
                .font(.headline)
        }
        .padding(.vertical, 4)
    }
}
