import Domain
import Foundation

/// What the UI should say about data freshness, derived from `Fetched.Freshness`.
public enum SyncStatus: Equatable, Sendable {
    case upToDate
    case refreshing
    case offline(lastSynced: Date?)
    case refreshFailed(lastSynced: Date?)

    init(_ freshness: Fetched<some Sendable>.Freshness) {
        switch freshness {
        case .fresh:
            self = .upToDate
        case .cached:
            self = .refreshing
        case .stale(let syncedAt, .offline):
            self = .offline(lastSynced: syncedAt)
        case .stale(let syncedAt, _):
            self = .refreshFailed(lastSynced: syncedAt)
        }
    }

    public var isStale: Bool {
        switch self {
        case .offline, .refreshFailed: true
        case .upToDate, .refreshing: false
        }
    }
}
