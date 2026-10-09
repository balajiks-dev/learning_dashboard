import Domain
import Foundation

public final class DefaultCourseRepository: CourseRepository {
    private let remote: any CourseRemoteDataSource
    private let store: CourseLocalStore
    private let now: @Sendable () -> Date
    private let syncQueue = SerialTaskQueue()

    public init(
        remote: any CourseRemoteDataSource,
        store: CourseLocalStore,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.remote = remote
        self.store = store
        self.now = now
    }

    public func courses() -> AsyncThrowingStream<Fetched<[Course]>, Error> {
        cacheThenNetwork(
            cached: { [store] in try await store.cachedCourses() },
            refresh: { [self] in
                // Push before pull, so the fresh catalog already includes this
                // device's offline progress.
                await syncPendingChanges()
                let dtos = try await remote.fetchCourses()
                return try await store.saveCatalog(dtos, syncedAt: now())
            }
        )
    }

    public func courseDetail(id: Course.ID) -> AsyncThrowingStream<Fetched<CourseDetail>, Error> {
        cacheThenNetwork(
            cached: { [store] in try await store.cachedDetail(courseID: id) },
            refresh: { [self] in
                let dtos = try await remote.fetchLessons(courseID: id)
                return try await store.saveLessons(dtos, courseID: id, syncedAt: now())
            }
        )
    }

    /// Local-first: the completion is saved and returned immediately (online or
    /// not); the upload happens in the background via the outbox.
    public func completeLesson(_ lessonID: Lesson.ID, inCourse courseID: Course.ID) async throws -> CourseDetail {
        let detail: CourseDetail
        do {
            detail = try await store.markLessonCompleted(lessonID, courseID: courseID, at: now())
        } catch {
            throw DomainError(mapping: error)
        }
        Task { await self.syncPendingChanges() }
        return detail
    }

    public func syncPendingChanges() async {
        await syncQueue.run { [remote, store] in
            guard let pending = try? await store.pendingCompletions() else { return }
            for item in pending {
                do {
                    try await remote.markLessonCompleted(item.lessonID, courseID: item.courseID)
                    try await store.removePendingCompletion(lessonID: item.lessonID)
                } catch NetworkError.notFound {
                    // The lesson no longer exists server-side; retrying is pointless.
                    try? await store.removePendingCompletion(lessonID: item.lessonID)
                } catch NetworkError.offline, NetworkError.timeout {
                    return // Keep everything queued; retry on the next sync.
                } catch {
                    continue // Keep this item queued, try the rest.
                }
            }
        }
    }

    public func clearCache() async {
        try? await store.clearAll()
    }
}
