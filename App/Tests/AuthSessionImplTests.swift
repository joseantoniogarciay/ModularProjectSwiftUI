import Foundation
import XCTest
#if DEV
@testable import AppDev
#else
@testable import App
#endif
import Core

// MARK: - Test doubles
//
// These mocks use @unchecked Sendable to satisfy the protocols' `: Sendable`
// constraint. Invariant: all instances are created and accessed exclusively
// from the @MainActor-isolated test class; there is no concurrent access.

final class MockTokenStore: TokenStore, @unchecked Sendable {
    // Stubbed behavior (configure in tests)
    var stubbedTokens: AuthTokens?

    // Captured interactions (assert in tests)
    var savedTokens: AuthTokens?
    var clearCallCount = 0

    func load() async -> AuthTokens? { stubbedTokens }
    func save(_ tokens: AuthTokens) async { savedTokens = tokens }
    func clear() async { clearCallCount += 1; stubbedTokens = nil }
}

final class MockAccessRepository: AccessRepository, @unchecked Sendable {
    var stubbedLoginResult: LoginResult = .fixture()
    var stubbedLoginError: LoginError?

    var stubbedRegisterUser: User = .fixture()
    var stubbedRegisterError: RegisterError?

    func login(identifier: String, password: String) async throws(LoginError) -> LoginResult {
        if let error = stubbedLoginError { throw error }
        return stubbedLoginResult
    }

    func register(
        username: String,
        email: String,
        password: String
    ) async throws(RegisterError) -> User {
        if let error = stubbedRegisterError { throw error }
        return stubbedRegisterUser
    }
}

final class MockUserRepository: UserRepository, @unchecked Sendable {
    var stubbedUser: User = .fixture()
    var stubbedError: CurrentUserError?
    var callCount = 0

    func currentUser() async throws(CurrentUserError) -> User {
        callCount += 1
        if let error = stubbedError { throw error }
        return stubbedUser
    }
}

// MARK: - Fixtures

private extension User {
    static func fixture(id: String = "u1") -> User {
        User(id: id, username: "tester", email: "test@example.com", role: nil, avatarURL: nil)
    }
}

private extension AuthTokens {
    static func fixture() -> AuthTokens {
        AuthTokens(accessToken: "access", refreshToken: "refresh", accessTokenExpiresAt: nil)
    }
}

private extension LoginResult {
    static func fixture() -> LoginResult {
        LoginResult(user: .fixture(), tokens: .fixture())
    }
}

// MARK: - Tests

final class AuthSessionImplTests: XCTestCase {

    // Invariant: all four properties are accessed exclusively from
    // @MainActor-isolated test methods, and from setUp/tearDown which XCTest
    // guarantees run on the main thread (the main actor's executor).
    // nonisolated(unsafe) is required because XCTestCase.setUp/tearDown are
    // nonisolated in the type system despite running on the main thread, and
    // @MainActor on the test class would conflict with those base declarations.
    // Removal plan: remove nonisolated(unsafe) once XCTest annotates its
    // setUp/tearDown as @MainActor in a future SDK release.
    nonisolated(unsafe) var tokenStore: MockTokenStore!
    nonisolated(unsafe) var accessRepository: MockAccessRepository!
    nonisolated(unsafe) var userRepository: MockUserRepository!
    nonisolated(unsafe) var sut: AuthSessionImpl!

    override func setUp() {
        super.setUp()
        let store = MockTokenStore()
        let access = MockAccessRepository()
        let userRepo = MockUserRepository()
        // AuthSessionImpl.init is @MainActor; XCTest calls setUp on the main
        // thread, so assumeIsolated is safe here.
        let session = MainActor.assumeIsolated {
            AuthSessionImpl(tokenStore: store, accessRepository: access, userRepository: userRepo)
        }
        tokenStore = store
        accessRepository = access
        userRepository = userRepo
        sut = session
    }

    override func tearDown() {
        sut = nil
        tokenStore = nil
        accessRepository = nil
        userRepository = nil
        super.tearDown()
    }

    // MARK: - Initial state

    @MainActor
    func testInitialState_isUnknown() {
        guard case .unknown = sut.authState else {
            XCTFail("Expected .unknown, got \(sut.authState)")
            return
        }
    }

    // MARK: - restore()

    @MainActor
    func testRestore_noStoredToken_becomesAnonymousInitial() async {
        tokenStore.stubbedTokens = nil

        await sut.restore()

        guard case .anonymous(let reason) = sut.authState else {
            XCTFail("Expected .anonymous, got \(sut.authState)")
            return
        }
        XCTAssertEqual(reason, .initial)
    }

    @MainActor
    func testRestore_tokenExistsAndUserFetchSucceeds_becomesAuthenticated() async {
        tokenStore.stubbedTokens = .fixture()
        userRepository.stubbedUser = .fixture(id: "u42")

        await sut.restore()

        guard case .authenticated(let user) = sut.authState else {
            XCTFail("Expected .authenticated, got \(sut.authState)")
            return
        }
        XCTAssertEqual(user.id, "u42")
    }

    @MainActor
    func testRestore_tokenExistsButUserFetchFails_clearsTokenAndBecomesSessionExpired() async {
        tokenStore.stubbedTokens = .fixture()
        userRepository.stubbedError = .notAuthenticated

        await sut.restore()

        guard case .anonymous(let reason) = sut.authState else {
            XCTFail("Expected .anonymous, got \(sut.authState)")
            return
        }
        XCTAssertEqual(reason, .sessionExpired)
        XCTAssertEqual(
            tokenStore.clearCallCount, 1,
            "Token should have been cleared on failed restore"
        )
    }

    @MainActor
    func testRestore_calledWhenNotUnknown_isANoOp() async {
        // First call moves state from .unknown.
        await sut.restore() // → .anonymous(.initial)
        let callCountAfterFirst = userRepository.callCount

        // Second call should not trigger any further work.
        await sut.restore()

        XCTAssertEqual(
            userRepository.callCount, callCountAfterFirst,
            "restore() must early-exit when state is already known"
        )
    }

    // MARK: - login()

    @MainActor
    func testLogin_success_becomesAuthenticated() async throws {
        let expectedUser = User.fixture(id: "logged-in")
        accessRepository.stubbedLoginResult = LoginResult(user: expectedUser, tokens: .fixture())

        try await sut.login(identifier: "test@example.com", password: "pass")

        guard case .authenticated(let user) = sut.authState else {
            XCTFail("Expected .authenticated, got \(sut.authState)")
            return
        }
        XCTAssertEqual(user.id, "logged-in")
    }

    @MainActor
    func testLogin_success_persistsTokens() async throws {
        try await sut.login(identifier: "test@example.com", password: "pass")
        XCTAssertNotNil(tokenStore.savedTokens, "Tokens must be persisted after a successful login")
    }

    @MainActor
    func testLogin_repositoryThrows_propagatesError() async {
        accessRepository.stubbedLoginError = .invalidCredentials

        do {
            try await sut.login(identifier: "bad", password: "bad")
            XCTFail("Expected login to throw")
        } catch {
            guard case .invalidCredentials = error else {
                XCTFail("Expected .invalidCredentials, got \(error)")
                return
            }
        }
    }

    // MARK: - logout()

    @MainActor
    func testLogout_clearsTokenAndBecomesUserLoggedOut() async {
        try? await sut.login(identifier: "u", password: "p")

        await sut.logout()

        guard case .anonymous(let reason) = sut.authState else {
            XCTFail("Expected .anonymous, got \(sut.authState)")
            return
        }
        XCTAssertEqual(reason, .userLoggedOut)
        XCTAssertGreaterThanOrEqual(
            tokenStore.clearCallCount, 1,
            "Token should be cleared on logout"
        )
    }

    // MARK: - expireSession()

    @MainActor
    func testExpireSession_clearsTokenAndBecomesSessionExpired() async {
        try? await sut.login(identifier: "u", password: "p")

        await sut.expireSession()

        guard case .anonymous(let reason) = sut.authState else {
            XCTFail("Expected .anonymous, got \(sut.authState)")
            return
        }
        XCTAssertEqual(reason, .sessionExpired)
        XCTAssertGreaterThanOrEqual(
            tokenStore.clearCallCount, 1,
            "Token should be cleared on session expiry"
        )
    }

    // MARK: - register()

    @MainActor
    func testRegister_success_becomesAuthenticated() async throws {
        // register() auto-logs-in after a successful sign-up.
        let expectedUser = User.fixture(id: "new-user")
        accessRepository.stubbedLoginResult = LoginResult(user: expectedUser, tokens: .fixture())

        try await sut.register(username: "newuser", email: "new@example.com", password: "pass")

        guard case .authenticated(let user) = sut.authState else {
            XCTFail("Expected .authenticated after register, got \(sut.authState)")
            return
        }
        XCTAssertEqual(user.id, "new-user")
    }

    @MainActor
    func testRegister_signUpFails_throwsMatchingError() async {
        // MockAccessRepository.register() throws RegisterError.usernameOrEmailTaken.
        // AuthSessionImpl.register() maps it to SignUpError.usernameOrEmailTaken.
        accessRepository.stubbedRegisterError = .usernameOrEmailTaken

        do {
            try await sut.register(username: "taken", email: "taken@example.com", password: "pass")
            XCTFail("Expected register to throw")
        } catch {
            guard case .usernameOrEmailTaken = error else {
                XCTFail("Expected .usernameOrEmailTaken (SignUpError), got \(error)")
                return
            }
        }
    }

    @MainActor
    func testRegister_autoLoginFails_throwsAutoLoginFailed() async {
        // Sign-up succeeds but the subsequent auto-login fails.
        accessRepository.stubbedRegisterError = nil
        accessRepository.stubbedLoginError = .noConnection

        do {
            try await sut.register(username: "u", email: "u@example.com", password: "p")
            XCTFail("Expected register to throw")
        } catch {
            guard case .autoLoginFailed = error else {
                XCTFail("Expected .autoLoginFailed (SignUpError), got \(error)")
                return
            }
        }
    }

    // MARK: - authStates() stream

    @MainActor
    func testAuthStates_emitsCurrentStateImmediately() async {
        // After restore() the state is .anonymous(.initial).
        await sut.restore()

        let stream = sut.authStates()
        var received: [AuthState] = []
        for await state in stream {
            received.append(state)
            break // only consume the buffered current-state value
        }

        XCTAssertEqual(received.count, 1)
        guard case .anonymous(let reason) = received.first else {
            XCTFail("Expected .anonymous, got \(String(describing: received.first))")
            return
        }
        XCTAssertEqual(reason, .initial)
    }

    // MARK: - refreshCurrentUser()

    @MainActor
    func testRefreshCurrentUser_success_updatesAuthenticatedUser() async throws {
        // Start authenticated so refresh has something to update.
        try await sut.login(identifier: "u", password: "p")

        let updatedUser = User.fixture(id: "refreshed")
        userRepository.stubbedUser = updatedUser

        try await sut.refreshCurrentUser()

        guard case .authenticated(let user) = sut.authState else {
            XCTFail("Expected .authenticated after refresh, got \(sut.authState)")
            return
        }
        XCTAssertEqual(user.id, "refreshed")
    }

    @MainActor
    func testRefreshCurrentUser_repositoryThrows_propagatesError() async {
        userRepository.stubbedError = .notAuthenticated

        do {
            try await sut.refreshCurrentUser()
            XCTFail("Expected refreshCurrentUser to throw")
        } catch {
            guard case .notAuthenticated = error else {
                XCTFail("Expected .notAuthenticated, got \(error)")
                return
            }
        }
    }
}
