import Domain
import Observation

@MainActor
@Observable
public final class CourseDetailViewModel {
    /// The summary from the list, shown in the header while lessons load.
    public let summary: Course
    public private(set) var state: LoadState<CourseDetail> = .idle
    public private(set) var syncStatus: SyncStatus = .upToDate
    public private(set) var completingLessonIDs: Set<Lesson.ID> = []
    public var alert: DomainError?

    private let getDetail: GetCourseDetailUseCase
    private let completeLesson: CompleteLessonUseCase
    private let onCourseUpdated: @MainActor (Course) -> Void

    public init(
        course: Course,
        getDetail: GetCourseDetailUseCase,
        completeLesson: CompleteLessonUseCase,
        onCourseUpdated: @escaping @MainActor (Course) -> Void = { _ in }
    ) {
        self.summary = course
        self.getDetail = getDetail
        self.completeLesson = completeLesson
        self.onCourseUpdated = onCourseUpdated
    }

    public var course: Course { state.value?.course ?? summary }

    public func load() async {
        if state.value == nil { state = .loading }
        do {
            for try await result in getDetail(courseID: summary.id) {
                state = .loaded(result.value)
                syncStatus = SyncStatus(result.freshness)
                onCourseUpdated(result.value.course)
            }
        } catch {
            let error = DomainError(error)
            if state.value == nil {
                state = .failed(error)
            } else {
                syncStatus = .refreshFailed(lastSynced: nil)
            }
        }
    }

    /// Optimistic update: the UI changes instantly using the same domain rule
    /// the store applies, then reconciles with the persisted result (or rolls back).
    public func complete(_ lesson: Lesson) async {
        guard case .loaded(let before) = state,
              !lesson.isCompleted,
              !completingLessonIDs.contains(lesson.id),
              let optimistic = try? before.markingLessonCompleted(lesson.id)
        else { return }

        completingLessonIDs.insert(lesson.id)
        defer { completingLessonIDs.remove(lesson.id) }
        apply(optimistic)

        do {
            apply(try await completeLesson(lesson))
        } catch {
            apply(before)
            alert = DomainError(error)
        }
    }

    private func apply(_ detail: CourseDetail) {
        state = .loaded(detail)
        onCourseUpdated(detail.course)
    }
}
