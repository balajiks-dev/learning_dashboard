import Domain
import Foundation

/// Scripted repository: each call replays the configured events.
struct FakeCourseRepository: CourseRepository {
    var courseEvents: [Fetched<[Course]>] = []
    var courseError: DomainError?
    var detailEvents: [Fetched<CourseDetail>] = []
    var completionError: DomainError?

    func courses() -> AsyncThrowingStream<Fetched<[Course]>, Error> {
        replay(courseEvents, then: courseError)
    }

    func courseDetail(id: Course.ID) -> AsyncThrowingStream<Fetched<CourseDetail>, Error> {
        replay(detailEvents, then: nil)
    }

    func completeLesson(_ lessonID: Lesson.ID, inCourse courseID: Course.ID) async throws -> CourseDetail {
        if let completionError { throw completionError }
        guard let detail = detailEvents.last?.value else { throw DomainError.notFound }
        return try detail.markingLessonCompleted(lessonID)
    }

    func syncPendingChanges() async {}
    func clearCache() async {}

    private func replay<T: Sendable>(_ events: [T], then error: DomainError?) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { continuation in
            events.forEach { continuation.yield($0) }
            continuation.finish(throwing: error)
        }
    }
}

struct FakeConnectivity: ConnectivityMonitoring {
    var isConnected = true
    func connectivityUpdates() -> AsyncStream<Bool> {
        AsyncStream { $0.yield(isConnected); $0.finish() }
    }
}

actor FakeAuthRepository: AuthRepository {
    var loginCalls = 0
    var result: Result<User, DomainError> = .success(.sample)

    init(result: Result<User, DomainError> = .success(.sample)) {
        self.result = result
    }

    func login(email: String, password: String) async throws -> User {
        loginCalls += 1
        return try result.get()
    }

    func currentUser() async -> User? { nil }
    func logout() async {}
}

extension User {
    static let sample = User(id: "u_001", name: "Learner", email: "learner@example.com")
}

extension Course {
    static let python = Course(id: 1, title: "Python Programming", instructor: "John Smith", progress: 50, lessonCount: 4)
}

extension CourseDetail {
    static let python = CourseDetail(course: .python, lessons: [
        Lesson(id: 101, courseID: 1, title: "Introduction", position: 1, isCompleted: true),
        Lesson(id: 102, courseID: 1, title: "Variables", position: 2, isCompleted: true),
        Lesson(id: 103, courseID: 1, title: "Functions", position: 3, isCompleted: false),
        Lesson(id: 104, courseID: 1, title: "OOP", position: 4, isCompleted: false),
    ])
}
