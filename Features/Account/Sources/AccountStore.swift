import Core
import Foundation
import Observation

@Observable @MainActor
public final class AccountStore {
    public private(set) var authState: AuthState = .unknown
    public private(set) var sessionExpiredAlert = false

    private let session: any AuthSession

    public init(session: any AuthSession) {
        self.session = session
    }

    /// Starts session restoration and begins observing auth state changes.
    /// Call this from `.task` on the root account view.
    public func start() async {
        // Restore session first; authStates() immediately yields the post-restore state.
        await session.restore()
        var previous: AuthState?
        for await state in session.authStates() {
            if case .anonymous(.sessionExpired) = state,
               case .authenticated = previous {
                sessionExpiredAlert = true
            }
            authState = state
            previous = state
        }
    }

    public func dismissSessionExpiredAlert() {
        sessionExpiredAlert = false
    }

    public func login(identifier: String, password: String) async throws(LoginError) {
        try await session.login(identifier: identifier, password: password)
    }

    public func register(username: String, email: String, password: String) async throws(SignUpError) {
        try await session.register(username: username, email: email, password: password)
    }

    public func refreshCurrentUser() async {
        try? await session.refreshCurrentUser()
    }

    public func logout() async {
        await session.logout()
    }
}
