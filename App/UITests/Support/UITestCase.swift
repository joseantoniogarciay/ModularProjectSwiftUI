import XCTest

/// Base class that owns the XCUIApplication lifecycle for all UI test classes.
///
/// Subclasses override `launchArguments` to select a dependency variant:
/// - `["--uitesting"]`            → in-memory stubs, all succeed (default)
/// - `["--uitesting-list-error"]` → Pokémon list repository throws `.noConnection`
///
/// Swift 6 concurrency rationale:
/// `XCUIApplication` is `@MainActor`. `setUp`/`tearDown` are `nonisolated` in XCTestCase.
/// • `nonisolated(unsafe) var app` — invariant: only accessed from `@MainActor` test methods
///   and from setUp/tearDown which XCTest guarantees run on the main thread.
/// • `MainActor.assumeIsolated` in setUp/tearDown to satisfy the compiler without annotating
///   the entire class as `@MainActor` (which would conflict with nonisolated setUp/tearDown).
/// Removal plan: remove `nonisolated(unsafe)` + `assumeIsolated` once XCTest annotates
/// setUp/tearDown as `@MainActor` in a future SDK release.
class UITestCase: XCTestCase {

    nonisolated(unsafe) var app: XCUIApplication!

    /// Launch arguments forwarded to `XCUIApplication`. Override in subclasses
    /// to select a different dependency variant.
    var launchArguments: [String] { ["--uitesting"] }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        let args = launchArguments  // capture before closure — avoid self capture
        let application = MainActor.assumeIsolated {
            let a = XCUIApplication()
            a.launchArguments = args
            a.launch()
            return a
        }
        app = application
    }

    override func tearDown() {
        let application = app
        MainActor.assumeIsolated { application?.terminate() }
        app = nil
        super.tearDown()
    }
}
