import Domain
import Foundation
@testable import DataLayer

/// A controllable fake server for repository tests.
actor StubCourseRemote: CourseRemoteDataSource {
    var isOnline = true
    var courses: [CourseDTO]
    var lessons: [Int: [LessonDTO]]
    /// When false, the server "forgets" completions (simulates a lagging backend).
    var persistsCompletions = true
    private(set) var uploadedCompletions: [Int] = []

    init(courses: [CourseDTO] = StubCourseRemote.sampleCourses, lessons: [Int: [LessonDTO]] = StubCourseRemote.sampleLessons) {
        self.courses = courses
        self.lessons = lessons
    }

    func setOnline(_ online: Bool) { isOnline = online }
    func setPersistsCompletions(_ value: Bool) { persistsCompletions = value }
    func setCourses(_ courses: [CourseDTO]) { self.courses = courses }

    func fetchCourses() async throws -> [CourseDTO] {
        guard isOnline else { throw NetworkError.offline }
        return courses
    }

    func fetchLessons(courseID: Int) async throws -> [LessonDTO] {
        guard isOnline else { throw NetworkError.offline }
        guard let lessons = lessons[courseID] else { throw NetworkError.notFound }
        return lessons
    }

    func markLessonCompleted(_ lessonID: Int, courseID: Int) async throws {
        guard isOnline else { throw NetworkError.offline }
        uploadedCompletions.append(lessonID)
        if persistsCompletions, let index = lessons[courseID]?.firstIndex(where: { $0.id == lessonID }) {
            lessons[courseID]?[index].completed = true
        }
    }

    static let sampleCourses = [
        CourseDTO(id: 1, title: "Python Programming", instructor: "John Smith", progress: 50, lessons: 4),
        CourseDTO(id: 2, title: "Generative AI", instructor: "Sarah Williams", progress: 0, lessons: 2),
    ]

    static let sampleLessons: [Int: [LessonDTO]] = [
        1: [
            LessonDTO(id: 101, title: "Introduction", order: 1, completed: true),
            LessonDTO(id: 102, title: "Variables & Data Types", order: 2, completed: true),
            LessonDTO(id: 103, title: "Functions", order: 3, completed: false),
            LessonDTO(id: 104, title: "OOP", order: 4, completed: false),
        ],
        2: [
            LessonDTO(id: 201, title: "What is Generative AI", order: 1, completed: false),
            LessonDTO(id: 202, title: "Prompt Engineering", order: 2, completed: false),
        ],
    ]
}

struct AlwaysOnline: ConnectivityMonitoring {
    var isConnected: Bool { true }
    func connectivityUpdates() -> AsyncStream<Bool> { AsyncStream { $0.yield(true); $0.finish() } }
}

func collect<Value>(_ stream: AsyncThrowingStream<Value, Error>) async throws -> [Value] {
    var values: [Value] = []
    for try await value in stream { values.append(value) }
    return values
}
