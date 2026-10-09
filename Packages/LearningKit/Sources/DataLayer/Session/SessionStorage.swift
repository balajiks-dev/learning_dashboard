import Foundation
import os

public struct StoredSession: Codable, Equatable, Sendable {
    public let token: String
    public let user: UserDTO

    public init(token: String, user: UserDTO) {
        self.token = token
        self.user = user
    }
}

public protocol SessionStorage: Sendable {
    func load() -> StoredSession?
    func save(_ session: StoredSession) throws
    func clear()
}

/// Used by tests and SwiftUI previews.
public final class InMemorySessionStorage: SessionStorage {
    private let session: OSAllocatedUnfairLock<StoredSession?>

    public init(session: StoredSession? = nil) {
        self.session = OSAllocatedUnfairLock(initialState: session)
    }

    public func load() -> StoredSession? { session.withLock { $0 } }
    public func save(_ session: StoredSession) throws { self.session.withLock { $0 = session } }
    public func clear() { session.withLock { $0 = nil } }
}
