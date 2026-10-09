/// A course together with its lessons.
///
/// Once lessons are known they are the single source of truth for progress:
/// the initializer re-derives `course.progress` from them, so a detail value
/// can never hold a progress number that disagrees with its own lessons.
public struct CourseDetail: Equatable, Sendable {
    public let course: Course
    public let lessons: [Lesson]

    public init(course: Course, lessons: [Lesson]) {
        let sorted = lessons.sorted { $0.position < $1.position }
        self.lessons = sorted
        if sorted.isEmpty {
            self.course = course
        } else {
            let completed = sorted.lazy.filter(\.isCompleted).count
            self.course = course.updating(
                progress: ProgressCalculator.percentage(completed: completed, total: sorted.count),
                lessonCount: sorted.count
            )
        }
    }

    public var completedCount: Int { lessons.lazy.filter(\.isCompleted).count }
    public var progress: Int { course.progress }
    public var nextLesson: Lesson? { lessons.first { !$0.isCompleted } }

    /// Pure state transition shared by the optimistic UI update and the
    /// persistence layer, so both apply exactly the same rule.
    /// Completing an already-completed lesson is a no-op (idempotent).
    public func markingLessonCompleted(_ lessonID: Lesson.ID) throws(DomainError) -> CourseDetail {
        guard let index = lessons.firstIndex(where: { $0.id == lessonID }) else {
            throw .notFound
        }
        guard !lessons[index].isCompleted else { return self }
        var updated = lessons
        updated[index] = updated[index].markedCompleted()
        return CourseDetail(course: course, lessons: updated)
    }
}
