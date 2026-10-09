public protocol CourseRemoteDataSource: Sendable {
    func fetchCourses() async throws -> [CourseDTO]
    func fetchLessons(courseID: Int) async throws -> [LessonDTO]
    func markLessonCompleted(_ lessonID: Int, courseID: Int) async throws
}

public struct APICourseRemoteDataSource: CourseRemoteDataSource {
    private let client: APIClient

    public init(client: APIClient) {
        self.client = client
    }

    public func fetchCourses() async throws -> [CourseDTO] {
        try await client.request(.courses)
    }

    public func fetchLessons(courseID: Int) async throws -> [LessonDTO] {
        try await client.request(.lessons(courseID: courseID))
    }

    public func markLessonCompleted(_ lessonID: Int, courseID: Int) async throws {
        try await client.send(.completeLesson(lessonID, courseID: courseID))
    }
}
