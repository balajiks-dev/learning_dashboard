import Testing
@testable import Domain

@Suite("Completing a lesson")
struct CourseDetailTests {
    private let detail = CourseDetail(
        course: Course(id: 1, title: "Python Programming", instructor: "John Smith", progress: 0, lessonCount: 0),
        lessons: [
            Lesson(id: 3, courseID: 1, title: "Functions", position: 3, isCompleted: false),
            Lesson(id: 1, courseID: 1, title: "Introduction", position: 1, isCompleted: true),
            Lesson(id: 2, courseID: 1, title: "Variables & Data Types", position: 2, isCompleted: true),
            Lesson(id: 4, courseID: 1, title: "OOP", position: 4, isCompleted: false),
        ]
    )

    @Test("Progress is derived from lessons, not trusted from the course summary")
    func derivedProgress() {
        #expect(detail.course.progress == 50)
        #expect(detail.course.lessonCount == 4)
        #expect(detail.lessons.map(\.position) == [1, 2, 3, 4])
        #expect(detail.nextLesson?.title == "Functions")
    }

    @Test("Marking a pending lesson updates its status and the course progress")
    func markCompleted() throws {
        let updated = try detail.markingLessonCompleted(3)

        #expect(updated.lessons.first { $0.id == 3 }?.isCompleted == true)
        #expect(updated.completedCount == 3)
        #expect(updated.course.progress == 75)
        #expect(updated.nextLesson?.title == "OOP")
    }

    @Test("Completing an already-completed lesson is a no-op")
    func idempotent() throws {
        #expect(try detail.markingLessonCompleted(1) == detail)
    }

    @Test("Completing an unknown lesson throws notFound")
    func unknownLesson() {
        #expect(throws: DomainError.notFound) { try detail.markingLessonCompleted(99) }
    }
}
