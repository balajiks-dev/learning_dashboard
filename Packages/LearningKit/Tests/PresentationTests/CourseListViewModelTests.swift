import Domain
import Foundation
import Testing
@testable import Presentation

@MainActor
@Suite("Course list screen states")
struct CourseListViewModelTests {
    private func makeViewModel(_ repository: FakeCourseRepository) -> CourseListViewModel {
        CourseListViewModel(getCourses: GetCoursesUseCase(repository: repository), connectivity: FakeConnectivity())
    }

    @Test("Success: shows courses and is up to date")
    func success() async {
        let viewModel = makeViewModel(FakeCourseRepository(courseEvents: [.init(value: [.python], freshness: .fresh)]))
        await viewModel.load()

        #expect(viewModel.state == .loaded([.python]))
        #expect(viewModel.syncStatus == .upToDate)
    }

    @Test("Empty: an empty catalog shows the empty state, not an error")
    func empty() async {
        let viewModel = makeViewModel(FakeCourseRepository(courseEvents: [.init(value: [], freshness: .fresh)]))
        await viewModel.load()

        #expect(viewModel.state == .empty)
    }

    @Test("Failure: no cache and an API error shows the error state")
    func failure() async {
        let viewModel = makeViewModel(FakeCourseRepository(courseError: .server(statusCode: 500)))
        await viewModel.load()

        #expect(viewModel.state == .failed(.server(statusCode: 500)))
    }

    @Test("Offline: cached courses stay visible with an offline banner")
    func offlineWithCache() async {
        let syncedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let viewModel = makeViewModel(FakeCourseRepository(courseEvents: [
            .init(value: [.python], freshness: .cached(syncedAt: syncedAt)),
            .init(value: [.python], freshness: .stale(syncedAt: syncedAt, reason: .offline)),
        ]))
        await viewModel.load()

        #expect(viewModel.state == .loaded([.python]))
        #expect(viewModel.syncStatus == .offline(lastSynced: syncedAt))
    }
}
