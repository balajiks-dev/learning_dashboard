import Domain
import Foundation
import Network
import os

/// NWPathMonitor-backed reachability with a fan-out `AsyncStream` per
/// subscriber. In DEBUG builds `isSimulatingOffline` lets the demo toggle
/// offline mode without touching the Mac's Wi-Fi.
///
/// `@unchecked Sendable`: `NWPathMonitor` is only touched in `init`/`deinit`;
/// all mutable state lives behind `OSAllocatedUnfairLock`.
public final class NetworkMonitor: ConnectivityMonitoring, @unchecked Sendable {
    private struct State {
        var pathSatisfied = true
        var simulatingOffline = false
        var subscribers: [UUID: AsyncStream<Bool>.Continuation] = [:]
        var isConnected: Bool { pathSatisfied && !simulatingOffline }
    }

    private let monitor = NWPathMonitor()
    private let state = OSAllocatedUnfairLock(initialState: State())

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            self?.update { $0.pathSatisfied = path.status == .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "learningdashboard.network-monitor"))
    }

    deinit {
        monitor.cancel()
    }

    public var isConnected: Bool {
        state.withLockUnchecked { $0.isConnected }
    }

    public var isSimulatingOffline: Bool {
        get { state.withLockUnchecked { $0.simulatingOffline } }
        set { update { $0.simulatingOffline = newValue } }
    }

    public func connectivityUpdates() -> AsyncStream<Bool> {
        let (stream, continuation) = AsyncStream<Bool>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let id = UUID()
        let current = state.withLockUnchecked { state in
            state.subscribers[id] = continuation
            return state.isConnected
        }
        continuation.onTermination = { [weak self] _ in
            self?.state.withLockUnchecked { _ = $0.subscribers.removeValue(forKey: id) }
        }
        continuation.yield(current)
        return stream
    }

    private func update(_ mutate: (inout State) -> Void) {
        let (changed, isConnected, subscribers) = state.withLockUnchecked { state in
            let before = state.isConnected
            mutate(&state)
            return (before != state.isConnected, state.isConnected, Array(state.subscribers.values))
        }
        guard changed else { return }
        subscribers.forEach { $0.yield(isConnected) }
    }
}
