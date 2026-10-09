public protocol CourseRepository: Sendable {
    /// Cache-then-network: emits the cached catalog immediately (if any), then
    /// the fresh one. If the refresh fails after a cached value was emitted,
    /// the stream re-emits the cache as `.stale` instead of throwing.
    func courses() -> AsyncThrowingStream<Fetched<[Course]>, Error>

    /// Same policy as `courses()`, for a single course and its lessons.
    func courseDetail(id: Course.ID) -> AsyncThrowingStream<Fetched<CourseDetail>, Error>

    /// Persists the completion locally (works offline) and queues it for upload.
    func completeLesson(_ lessonID: Lesson.ID, inCourse courseID: Course.ID) async throws -> CourseDetail

    /// Uploads queued offline changes. Safe to call at any time.
    func syncPendingChanges() async

    func clearCache() async
}
