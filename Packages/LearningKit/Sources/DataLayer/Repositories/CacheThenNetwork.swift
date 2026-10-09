import Domain
import Foundation

/// The offline policy, in one place:
/// 1. emit the cached value instantly (if there is one),
/// 2. fetch from the network, store it, emit it as `.fresh`,
/// 3. if the network fails, downgrade the cached value to `.stale` rather
///    than failing; throw only when there is nothing to show at all.
func cacheThenNetwork<Value: Sendable>(
    cached: @escaping @Sendable () async throws -> (Value, Date)?,
    refresh: @escaping @Sendable () async throws -> Value
) -> AsyncThrowingStream<Fetched<Value>, Error> {
    AsyncThrowingStream { continuation in
        let task = Task {
            // A corrupt cache must never block a network load.
            let cachedValue = try? await cached()
            if let (value, syncedAt) = cachedValue {
                continuation.yield(Fetched(value: value, freshness: .cached(syncedAt: syncedAt)))
            }
            do {
                let value = try await refresh()
                continuation.yield(Fetched(value: value, freshness: .fresh))
                continuation.finish()
            } catch {
                if error is CancellationError || Task.isCancelled {
                    continuation.finish()
                    return
                }
                let reason = DomainError(mapping: error)
                if let (value, syncedAt) = cachedValue {
                    continuation.yield(Fetched(value: value, freshness: .stale(syncedAt: syncedAt, reason: reason)))
                    continuation.finish()
                } else {
                    continuation.finish(throwing: reason)
                }
            }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}
