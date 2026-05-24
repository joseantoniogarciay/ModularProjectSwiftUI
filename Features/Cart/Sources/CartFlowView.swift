import Core
import SwiftUI

/// Cart tab root — owns the NavigationStack and hosts CartView.
/// Mirrors CartCoordinator from the UIKit project.
public struct CartFlowView: View {
    @State private var store: CartStore

    public init(store: CartStore) {
        self._store = State(initialValue: store)
    }

    public var body: some View {
        NavigationStack {
            CartView(store: store)
        }
    }
}
