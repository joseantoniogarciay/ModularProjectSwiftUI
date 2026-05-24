import XCTest

/// Page Object for the Pokémon list screen.
///
/// Encapsulates all XCUI element queries and gestures for this screen.
/// Test methods must call Page Object APIs only — no raw XCUIElement access in test code.
///
/// `@MainActor` is required because all `XCUIApplication` properties and methods are
/// main-actor-isolated under Swift 6 strict concurrency.
@MainActor
struct PokemonListScreen {
    private let app: XCUIApplication

    init(app: XCUIApplication) {
        self.app = app
    }

    // MARK: - Elements

    /// The main list (accessibilityIdentifier = "pokemon.list.table").
    ///
    /// SwiftUI's `List` is backed by a `UICollectionView`, so it surfaces in the
    /// XCUI tree as a `collectionView` (not a `table`).
    var table: XCUIElement {
        app.collectionViews["pokemon.list.table"]
    }

    /// The full-screen error container
    /// (accessibilityIdentifier = "pokemon.list.retry" on the RetryView).
    ///
    /// SwiftUI propagates the container's identifier down to each leaf element
    /// (the warning image, the message text, and the retry button) rather than to a
    /// single wrapping element. We match any descendant carrying the identifier so the
    /// query resolves regardless of which leaf the snapshot returns first.
    var retryContainer: XCUIElement {
        app.descendants(matching: .any).matching(identifier: "pokemon.list.retry").firstMatch
    }

    // MARK: - Queries

    /// Blocks until the list table appears or `timeout` elapses. Returns true if found.
    @discardableResult
    func waitForTable(timeout: TimeInterval = 3) -> Bool {
        table.waitForExistence(timeout: timeout)
    }

    /// Blocks until the full-screen error container appears or `timeout` elapses.
    @discardableResult
    func waitForRetry(timeout: TimeInterval = 3) -> Bool {
        retryContainer.waitForExistence(timeout: timeout)
    }

    /// The number of Pokémon rows currently visible in the list.
    ///
    /// Rows are `NavigationLink`s that surface as `buttons` in the XCUI tree;
    /// each carries an identifier of the form `"pokemon.cell.<name>"`.
    var rowCount: Int {
        app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'pokemon.cell.'")
        ).count
    }

    /// Returns the cell for the Pokémon with the given name.
    /// Matched via `accessibilityIdentifier = "pokemon.cell.<name.lowercased()>"`.
    ///
    /// In SwiftUI the row identifier is applied to the `NavigationLink`, which surfaces
    /// as a `button` (the enclosing collection-view cell carries no identifier), so the
    /// row is queried as a `button`. The name/number `StaticText`s remain descendants.
    func cell(named name: String) -> XCUIElement {
        app.buttons["pokemon.cell.\(name.lowercased())"]
    }

    // MARK: - Actions

    /// Taps the cell for the named Pokémon and returns the detail Page Object.
    @discardableResult
    func tapCell(named name: String) -> PokemonDetailScreen {
        cell(named: name).tap()
        return PokemonDetailScreen(app: app)
    }
}
