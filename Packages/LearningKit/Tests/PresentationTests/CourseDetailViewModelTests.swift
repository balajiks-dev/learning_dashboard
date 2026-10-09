import Domain
import Testing
@testable import Presentation

@MainActor
@Suite("Course detail: lesson completion")
struct CourseDetailViewModelTests {
    @Test("Completing a lesson updates its status, the course progress, and notifies the list")
    func completeLesson() async throws {
        var notified: [Course] = []
        let repository = FakeCourseRepository(detailEvents: [.init(value: .python, freshness: .fresh)])
        let viewModel = CourseDetailViewModel(
            course: .python,
            getDetail: GetCourseDetailUseCase(repository: repository),
            completeLesson: CompleteLessonUseCase(repository: repository),
            onCourseUpdated: { notified.append($0) }
        )
        await viewModel.load()
        let functions = try #require(viewModel.state.value?.lessons.first { $0.id == 103 })

        await viewModel.complete(functions)

        #expect(viewModel.state.value?.lessons.first { $0.id == 103 }?.isCompleted == true)
        #expect(viewModel.course.progress == 75)
        #expect(notified.last?.progress == 75)
        #expect(viewModel.completingLessonIDs.isEmpty)
    }

    @Test("If saving fails, the optimistic update is rolled back and an alert is shown")
    func rollback() async throws {
        let repository = FakeCourseRepository(
            detailEvents: [.init(value: .python, freshness: .fresh)],
            completionError: .persistence
        )
        let viewModel = CourseDetailViewModel(
            course: .python,
            getDetail: GetCourseDetailUseCase(repository: repository),
            completeLesson: CompleteLessonUseCase(repository: repository)
        )
        await viewModel.load()
        let functions = try #require(viewModel.state.value?.lessons.first { $0.id == 103 })

        await viewModel.complete(functions)

        #expect(viewModel.state.value == .python)
        #expect(viewModel.alert == .persistence)
    }
}
