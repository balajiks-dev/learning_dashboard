public struct GetCoursesUseCase: Sendable {
    private let repository: any CourseRepository

    public init(repository: any CourseRepository) {
        self.repository = repository
    }

    public func callAsFunction() -> AsyncThrowingStream<Fetched<[Course]>, Error> {
        repository.courses()
    }
}

public struct GetCourseDetailUseCase: Sendable {
    private let repository: any CourseRepository

    public init(repository: any CourseRepository) {
        self.repository = repository
    }

    public func callAsFunction(courseID: Course.ID) -> AsyncThrowingStream<Fetched<CourseDetail>, Error> {
        repository.courseDetail(id: courseID)
    }
}

public struct CompleteLessonUseCase: Sendable {
    private let repository: any CourseRepository

    public init(repository: any CourseRepository) {
        self.repository = repository
    }

    public func callAsFunction(_ lesson: Lesson) async throws -> CourseDetail {
        try await repository.completeLesson(lesson.id, inCourse: lesson.courseID)
    }
}

public struct SyncPendingProgressUseCase: Sendable {
    private let repository: any CourseRepository

    public init(repository: any CourseRepository) {
        self.repository = repository
    }

    public func callAsFunction() async {
        await repository.syncPendingChanges()
    }
}
