/// Port for observing network reachability. Implemented in the data layer
/// (NWPathMonitor) and faked in tests.
public protocol ConnectivityMonitoring: Sendable {
    var isConnected: Bool { get }
    /// Emits the current status immediately, then every change.
    func connectivityUpdates() -> AsyncStream<Bool>
}
