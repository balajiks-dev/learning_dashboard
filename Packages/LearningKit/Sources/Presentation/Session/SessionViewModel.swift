import Domain
import Observation

/// Owns the app-level authentication phase that drives the root navigation.
@MainActor
@Observable
public final class SessionViewModel {
    public enum Phase: Equatable {
        case launching
        case signedOut
        case signedIn(User)
    }

    public private(set) var phase: Phase = .launching

    private let restoreSession: RestoreSessionUseCase
    private let logout: LogoutUseCase

    public init(restoreSession: RestoreSessionUseCase, logout: LogoutUseCase) {
        self.restoreSession = restoreSession
        self.logout = logout
    }

    public func restore() async {
        guard phase == .launching else { return }
        phase = await restoreSession().map(Phase.signedIn) ?? .signedOut
    }

    public func didSignIn(_ user: User) {
        phase = .signedIn(user)
    }

    public func signOut() async {
        await logout()
        phase = .signedOut
    }
}
