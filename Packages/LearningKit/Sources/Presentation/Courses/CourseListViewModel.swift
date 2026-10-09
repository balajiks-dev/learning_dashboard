import Domain
import Observation

@MainActor
@Observable
public final class CourseListViewModel {
    public private(set) var state: LoadState<[Course]> = .idle
    public private(set) var syncStatus: SyncStatus = .upToDate
    public private(set) var isConnected = true

    /// Invoked when the server rejects the stored token.
    public var onSessionExpired: (@MainActor () -> Void)?

    private let getCourses: GetCoursesUseCase
    private let connectivity: any ConnectivityMonitoring
    private var isLoading = false

    public init(getCourses: GetCoursesUseCase, connectivity: any ConnectivityMonitoring) {
        self.getCourses = getCourses
        self.connectivity = connectivity
        self.isConnected = connectivity.isConnected
    }

    /// Loads once per screen lifetime; later appearances keep what's on screen.
    public func loadIfNeeded() async {
        guard case .idle = state else { return }
        await load()
    }

    public func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        // Keep current content visible during pull-to-refresh.
        if state.value == nil { state = .loading }
        do {
            for try await result in getCourses() {
                state = result.value.isEmpty ? .empty : .loaded(result.value)
                syncStatus = SyncStatus(result.freshness)
                if case .stale(_, .sessionExpired) = result.freshness { onSessionExpired?() }
            }
        } catch {
            let error = DomainError(error)
            if error == .sessionExpired { onSessionExpired?() }
            if state.value == nil {
                state = .failed(error)
            } else {
                syncStatus = error == .offline ? .offline(lastSynced: nil) : .refreshFailed(lastSynced: nil)
            }
        }
    }

    /// Reflects reachability in the UI and silently refreshes once the
    /// connection comes back, so stale data heals itself.
    public func observeConnectivity() async {
        for await connected in connectivity.connectivityUpdates() {
            let cameBackOnline = connected && !isConnected
            isConnected = connected
            if cameBackOnline, syncStatus.isStale || state.value == nil {
                await load()
            }
        }
    }

    /// Called by the detail screen so progress changes show up immediately on return.
    public func courseDidChange(_ course: Course) {
        guard case .loaded(var courses) = state,
              let index = courses.firstIndex(where: { $0.id == course.id }) else { return }
        courses[index] = course
        state = .loaded(courses)
    }

    public var overallProgress: Int {
        guard let courses = state.value, !courses.isEmpty else { return 0 }
        let totalLessons = courses.reduce(0) { $0 + $1.lessonCount }
        let completedLessons = courses.reduce(0.0) { $0 + Double($1.lessonCount * $1.progress) / 100 }
        return ProgressCalculator.percentage(completed: Int(completedLessons.rounded()), total: totalLessons)
    }
}
