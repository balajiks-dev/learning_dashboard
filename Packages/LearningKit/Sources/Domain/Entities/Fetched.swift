import Foundation

/// A value plus where it came from, so the UI can be honest about staleness
/// (e.g. "You're offline · showing courses saved 5 min ago").
public struct Fetched<Value: Sendable>: Sendable {
    public enum Freshness: Equatable, Sendable {
        /// Just loaded from the network.
        case fresh
        /// Read from the local cache; a network refresh is still in flight.
        case cached(syncedAt: Date?)
        /// The refresh failed; this is the best data we have.
        case stale(syncedAt: Date?, reason: DomainError)
    }

    public let value: Value
    public let freshness: Freshness

    public init(value: Value, freshness: Freshness) {
        self.value = value
        self.freshness = freshness
    }
}

extension Fetched: Equatable where Value: Equatable {}
