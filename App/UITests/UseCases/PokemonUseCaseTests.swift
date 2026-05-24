import XCTest

// MARK: - Happy-path use cases (in-memory stubs, all succeed)

/// Use-case tests for the Pokémon flow.
///
/// Launched with `--uitesting` → `AppDependencies.uitesting()` →
/// `UITestPokemonRepository` returns 5 sample Pokémon instantly.
/// No server required. Runs on any iOS 17+ simulator.
final class PokemonUseCaseTests: UITestCase {

    // MARK: UC-1: List loads

    /// The list screen appears and shows at least one Pokémon row.
    @MainActor
    func testListLoadsAndShowsPokemon() {
        let list = PokemonListScreen(app: app)
        XCTAssertTrue(list.waitForTable(), "List must appear with in-memory stubs")
        XCTAssertGreaterThan(list.rowCount, 0, "At least one Pokémon button row must be visible")
    }

    // MARK: UC-2: Cell content

    /// The first cell shows the correct capitalized name and formatted Pokédex number.
    @MainActor
    func testFirstCellShowsNameAndNumber() {
        let list = PokemonListScreen(app: app)
        XCTAssertTrue(list.waitForTable())

        let cell = list.cell(named: "bulbasaur")
        XCTAssertTrue(
            cell.waitForExistence(timeout: 3),
            "Bulbasaur cell must be visible (identifier = 'pokemon.cell.bulbasaur')"
        )
        XCTAssertTrue(cell.staticTexts["Bulbasaur"].exists, "Cell must display 'Bulbasaur'")
        XCTAssertTrue(cell.staticTexts["#001"].exists,      "Cell must display '#001'")
    }

    // MARK: UC-3: List → Detail navigation

    /// Tapping a Pokémon pushes the detail screen with the correct navigation title.
    @MainActor
    func testTapPokemonNavigatesToDetail() {
        let list = PokemonListScreen(app: app)
        XCTAssertTrue(list.waitForTable())

        let detail = list.tapCell(named: "bulbasaur")
        XCTAssertTrue(detail.waitForScrollView(), "Detail scroll view must appear after tap")
        XCTAssertEqual(
            detail.navigationTitle,
            "Bulbasaur",
            "Navigation bar title must match the tapped Pokémon's capitalized name"
        )
    }

    // MARK: UC-4: Detail loads stats

    /// After navigating to detail, the Base Stats section appears once the async load resolves.
    @MainActor
    func testDetailLoadsStats() {
        let list = PokemonListScreen(app: app)
        XCTAssertTrue(list.waitForTable())

        let detail = list.tapCell(named: "bulbasaur")
        XCTAssertTrue(
            detail.waitForStats(),
            "'Base Stats' header must appear once the detail async load completes"
        )
        XCTAssertFalse(
            detail.loadingIndicator.exists,
            "Loading indicator must be gone after stats render"
        )
    }

    // MARK: UC-5: Detail → List back navigation

    /// Tapping back from detail returns to the Pokémon list.
    @MainActor
    func testBackFromDetailReturnsToList() {
        let list = PokemonListScreen(app: app)
        XCTAssertTrue(list.waitForTable())

        let detail = list.tapCell(named: "bulbasaur")
        XCTAssertTrue(detail.waitForScrollView())

        let listAgain = detail.tapBack()
        XCTAssertTrue(
            listAgain.waitForTable(),
            "List must be visible again after back navigation"
        )
    }

    // MARK: UC-6: Navigate to a different Pokémon

    /// Tapping a non-first cell navigates to the correct detail screen.
    @MainActor
    func testTapSecondPokemonNavigatesToCorrectDetail() {
        let list = PokemonListScreen(app: app)
        XCTAssertTrue(list.waitForTable())

        let detail = list.tapCell(named: "ivysaur")
        XCTAssertTrue(detail.waitForScrollView())
        XCTAssertEqual(
            detail.navigationTitle,
            "Ivysaur",
            "Navigation bar title must match the tapped Pokémon's name"
        )
    }
}

// MARK: - Error-state use cases

/// Use-case tests for the Pokémon list when the repository fails.
///
/// Launched with `--uitesting-list-error` → `UITestErrorPokemonRepository.list()`
/// always throws `.noConnection`.
final class PokemonListErrorTests: UITestCase {

    override var launchArguments: [String] { ["--uitesting-list-error"] }

    // MARK: UC-7: List error state

    /// When the initial list load fails, the full-screen error container is shown.
    @MainActor
    func testListErrorStateShowsRetryButton() {
        let list = PokemonListScreen(app: app)
        XCTAssertTrue(
            list.waitForRetry(),
            "Error container must appear when the initial list load throws .noConnection"
        )
        XCTAssertFalse(
            list.table.exists,
            "List must not exist in the hierarchy when the error view is shown (switch branch is mutually exclusive)"
        )
    }
}
