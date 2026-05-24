import Core
import Foundation
import Observation

public enum CartViewState: Sendable {
    case loading
    case error(CartFetchError)
    case loaded
}

@Observable @MainActor
public final class CartStore {
    public private(set) var cart: Cart = Cart(items: [], total: 0)
    public private(set) var viewState: CartViewState = .loading
    public private(set) var isAddingItem = false
    public var addErrorMessage: String?
    public var showNoProductsAlert = false

    private let cartRepository: any CartRepository
    private let productsRepository: any ProductsRepository
    private let onSimulateExpiration: @MainActor @Sendable () async -> Void

    public init(
        cartRepository: any CartRepository,
        productsRepository: any ProductsRepository,
        onSimulateExpiration: @escaping @MainActor @Sendable () async -> Void
    ) {
        self.cartRepository = cartRepository
        self.productsRepository = productsRepository
        self.onSimulateExpiration = onSimulateExpiration
    }

    public func load() async {
        viewState = .loading
        do {
            let fetched = try await cartRepository.get()
            cart = fetched
            viewState = .loaded
        } catch {
            viewState = .error(error)
        }
    }

    public func addRandomItem() async {
        guard !isAddingItem else { return }
        isAddingItem = true
        defer { isAddingItem = false }

        let products: [Product]
        do {
            products = try await productsRepository.list()
        } catch {
            let message: String
            switch error {
            case .noConnection: message = CoreStrings.errorNoConnection
            case .unknown: message = CoreStrings.cartAddFailed
            }
            addErrorMessage = message
            return
        }

        guard let productId = products.randomElement()?.id else {
            showNoProductsAlert = true
            return
        }

        do {
            let updated = try await cartRepository.addItem(productId: productId)
            cart = updated
            viewState = .loaded
        } catch {
            let message: String
            switch error {
            case .noConnection: message = CoreStrings.errorNoConnection
            case .unknown: message = CoreStrings.cartAddFailed
            }
            addErrorMessage = message
        }
    }

    public func simulateExpiration() async {
        await onSimulateExpiration()
    }
}
