import Core
import SharedUI
import SwiftUI

public struct CartView: View {
    @State var store: CartStore
    @Environment(\.openURL) private var openURL
    @Environment(\.bannerPresenter) private var bannerPresenter

    public init(store: CartStore) {
        self._store = State(initialValue: store)
    }

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    public var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let error):
                errorView(for: error)
            case .loaded:
                if store.cart.items.isEmpty {
                    Text(CoreStrings.cartEmpty)
                        .font(.body)
                        .foregroundStyle(SharedUIAsset.secondaryText.swiftUIColor)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 20)
                } else {
                    loadedContent
                }
            }
        }
        .background(SharedUIAsset.background.swiftUIColor.ignoresSafeArea())
        .navigationTitle(CoreStrings.cartScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .task { await store.load() }
        .alert(
            CoreStrings.cartNoProductsTitle,
            isPresented: $store.showNoProductsAlert
        ) {
            Button(CoreStrings.cartNoProductsOpenButton) {
                if let url = URL(string: "https://api.freeapi.app") {
                    openURL(url)
                }
            }
            Button(CoreStrings.cartNoProductsCancelButton, role: .cancel) {}
        } message: {
            Text(CoreStrings.cartNoProductsMessage)
        }
        .onChange(of: store.addErrorMessage) { _, message in
            guard let message else { return }
            bannerPresenter?.show(BannerPayload(
                message: message,
                style: .error,
                iconSystemName: "xmark.circle.fill"
            ))
            store.addErrorMessage = nil
        }
    }

    // MARK: - Loaded content

    private var loadedContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(store.cart.items, id: \.id) { item in
                    CartItemRowView(item: item)
                        .padding(.horizontal, 16)
                    if item.id != store.cart.items.last?.id {
                        Divider()
                    }
                }
            }
            .background(SharedUIAsset.cardBackground.swiftUIColor)
            .modifier(CartCardChrome(cornerRadius: 14))
            .padding(.horizontal, 24)
            .padding(.top, 24)

            HStack {
                Spacer()
                totalCard
                    .padding(.trailing, 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private var totalCard: some View {
        let total = Self.priceFormatter.string(from: NSNumber(value: store.cart.total))
            ?? String(format: "%.2f", store.cart.total)
        return Text(CoreStrings.cartTotalFormat(total))
            .font(.headline)
            .foregroundStyle(SharedUIAsset.text.swiftUIColor)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(SharedUIAsset.cardBackground.swiftUIColor)
            .modifier(CartCardChrome(cornerRadius: 14))
    }

    // MARK: - Error view

    private func errorView(for error: CartFetchError) -> some View {
        ContentUnavailableView {
            Label(CoreStrings.errorGenericLoading, systemImage: "exclamationmark.triangle")
        } description: {
            switch error {
            case .noConnection:
                Text(CoreStrings.errorNoConnection)
            case .unknown:
                Text(CoreStrings.errorGenericLoading)
            }
        } actions: {
            Button(CoreStrings.retryButtonTitle) {
                Task { await store.load() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(CoreStrings.cartSimulateExpireButton) {
                Task { await store.simulateExpiration() }
            }
            .tint(.red)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if store.isAddingItem {
                ProgressView()
            } else {
                Button {
                    Task { await store.addRandomItem() }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }
}

// MARK: - Card chrome (shadow in light / border in dark)

private struct CartCardChrome: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.09),
                radius: 10,
                x: 0,
                y: 3
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 0.5)
                    .opacity(colorScheme == .dark ? 1 : 0)
            }
    }
}
