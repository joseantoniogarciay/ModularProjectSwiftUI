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
    var table: XCUIElement {
        app.tables["pokemon.list.table"]
    }

    /// The full-screen error container
    /// (accessibilityIdentifier = "pokemon.list.retry" on the RetryView).
    /// The retry button is a child of this container.
    var retryContainer: XCUIElement {
        app.otherElements["pokemon.list.retry"]
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

    /// Returns the cell for the Pokémon with the given name.
    /// Matched via `accessibilityIdentifier = "pokemon.cell.<name.lowercased()>"`.
    func cell(named name: String) -> XCUIElement {
        app.cells["pokemon.cell.\(name.lowercased())"]
    }

    // MARK: - Actions

    /// Taps the cell for the named Pokémon and returns the detail Page Object.
    @discardableResult
    func tapCell(named name: String) -> PokemonDetailScreen {
        cell(named: name).tap()
        return PokemonDetailScreen(app: app)
    }
}
