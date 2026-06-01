import Core
import SharedUI
import SwiftUI

public struct CartView: View {
    @State var store: CartStore
    @Environment(\.bannerPresenter) private var bannerPresenter

    /// Stashed when the user confirms "open web": presented as an in-app Safari sheet once the
    /// confirmation dialog finishes dismissing, mirroring UIKit's `dismiss { presentSafari() }`.
    @State private var pendingSeedURL: URL?
    @State private var seedURL: SeedURL?

    /// Mirrors `store.showNoProductsAlert` but is toggled inside a `disablesAnimations`
    /// transaction so the `fullScreenCover`'s own present/dismiss slide is suppressed — the
    /// dialog itself cross-dissolves via its internal opacity, matching UIKit's `.crossDissolve`.
    @State private var dialogShown = false

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
        // Custom card dialog (mirrors UIKit's ConfirmationDialogViewController), presented over
        // the whole screen so the dim covers the nav bar too. When confirmed, the in-app Safari
        // is opened only after the dialog finishes dismissing — matching the UIKit chaining.
        .fullScreenCover(isPresented: $dialogShown) {
            if let url = pendingSeedURL {
                pendingSeedURL = nil
                seedURL = SeedURL(url: url)
            }
        } content: {
            ConfirmationDialogView(
                icon: "tray",
                title: CoreStrings.cartNoProductsTitle,
                message: CoreStrings.cartNoProductsMessage,
                confirmTitle: CoreStrings.cartNoProductsOpenButton,
                cancelTitle: CoreStrings.cartNoProductsCancelButton,
                onConfirm: {
                    pendingSeedURL = URL(string: "https://api.freeapi.app")
                    store.showNoProductsAlert = false
                },
                onCancel: { store.showNoProductsAlert = false }
            )
            .presentationBackground(.clear)
        }
        .sheet(item: $seedURL) { seed in
            SafariView(url: seed.url)
                .ignoresSafeArea()
        }
        // Mirror the store flag into `dialogShown` without animation so the cover never slides;
        // the dialog handles its own fade in/out. The dialog's callbacks set the store flag back
        // to false, which propagates here and tears the cover down once the fade has finished.
        .onChange(of: store.showNoProductsAlert) { _, newValue in
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) { dialogShown = newValue }
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
        // Break the two trailing items into separate Liquid Glass capsules so the expire
        // button and the add button don't share one pill. On iOS 17 they're already spaced.
        if #available(iOS 26.0, *) {
            ToolbarSpacer(.fixed, placement: .navigationBarTrailing)
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            if store.isAddingItem {
                ProgressView()
                    .tint(.primary)
            } else {
                Button {
                    Task { await store.addRandomItem() }
                } label: {
                    Image(systemName: "plus")
                }
                // Render in the label color (black in light, white in dark) instead of
                // inheriting the TabView accent tint, matching the UIKit add button.
                .tint(.primary)
            }
        }
    }
}

// MARK: - Seed URL wrapper

/// Identifiable wrapper so the seed-feed URL can drive `.sheet(item:)`.
private struct SeedURL: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
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
