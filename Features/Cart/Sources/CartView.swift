import Core
import SwiftUI
import UIKit

struct CartView: View {
    @State var store: CartStore

    private static let priceFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    var body: some View {
        Group {
            switch store.viewState {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .error(let error):
                errorView(for: error)
            case .loaded:
                if store.cart.items.isEmpty {
                    ContentUnavailableView(
                        CoreStrings.cartEmpty,
                        systemImage: "cart"
                    )
                } else {
                    loadedContent
                }
            }
        }
        .navigationTitle(CoreStrings.cartScreenTitle)
        .toolbar { toolbar }
        .task { await store.load() }
        .alert(
            CoreStrings.cartNoProductsTitle,
            isPresented: $store.showNoProductsAlert
        ) {
            Button(CoreStrings.cartNoProductsOpenButton) {
                UIApplication.shared.open(URL(string: "https://api.freeapi.app")!)
            }
            Button(CoreStrings.cartNoProductsCancelButton, role: .cancel) {}
        } message: {
            Text(CoreStrings.cartNoProductsMessage)
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { store.addErrorMessage != nil },
                set: { if !$0 { store.addErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.addErrorMessage ?? "")
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
                            .padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(CoreStrings.cartSimulateExpireButton) {
                Task { await store.simulateExpiration() }
            }
            .tint(.red)
        }
    }
}
