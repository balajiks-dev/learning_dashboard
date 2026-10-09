import Domain
import Foundation
import Testing
@testable import DataLayer

/// Exercises the real repository + real SwiftData store (in memory) against a
/// fake server: the offline behaviour the assignment asks for, end to end.
@Suite("Course repository: offline-first behaviour")
struct CourseRepositoryTests {
    private let remote = StubCourseRemote()
    private let syncDate = Date(timeIntervalSince1970: 1_700_000_000)
    private let repository: DefaultCourseRepository

    init() throws {
        let store = CourseLocalStore(modelContainer: try PersistenceController.makeContainer(inMemory: true))
        repository = DefaultCourseRepository(remote: remote, store: store, now: { [syncDate] in syncDate })
    }

    @Test("First launch online: fetches, caches, and emits fresh data")
    func firstLaunch() async throws {
        let results = try await collect(repository.courses())

        #expect(results.map(\.freshness) == [.fresh])
        #expect(results.last?.value.map(\.title) == ["Python Programming", "Generative AI"])
    }

    @Test("Previously loaded courses are still shown when the device is offline")
    func offlineAfterFirstLoad() async throws {
        _ = try await collect(repository.courses())
        await remote.setOnline(false)

        let results = try await collect(repository.courses())

        #expect(results.map(\.freshness) == [
            .cached(syncedAt: syncDate),
            .stale(syncedAt: syncDate, reason: .offline),
        ])
        #expect(results.last?.value.count == 2)
    }

    @Test("Offline with nothing cached fails with .offline")
    func offlineWithoutCache() async {
        await remote.setOnline(false)
        await #expect(throws: DomainError.offline) {
            _ = try await collect(repository.courses())
        }
    }

    @Test("An empty catalog from the server is cached as empty, not as 'never loaded'")
    func emptyCatalog() async throws {
        await remote.setCourses([])
        _ = try await collect(repository.courses())
        await remote.setOnline(false)

        let results = try await collect(repository.courses())
        #expect(results.first?.value.isEmpty == true)
    }

    @Test("A lesson completed offline is persisted, survives refreshes, and syncs once back online")
    func offlineCompletionRoundTrip() async throws {
        _ = try await collect(repository.courses())
        _ = try await collect(repository.courseDetail(id: 1))
        await remote.setOnline(false)

        // 1. Completing works offline and updates progress immediately.
        let completed = try await repository.completeLesson(103, inCourse: 1)
        #expect(completed.course.progress == 75)

        // 2. It's durable: an offline reload still shows it.
        let offlineReload = try await collect(repository.courseDetail(id: 1))
        #expect(offlineReload.last?.value.course.progress == 75)

        // 3. Back online, a server that hasn't seen the change can't revert it.
        await remote.setOnline(true)
        await remote.setPersistsCompletions(false)
        let refreshed = try await collect(repository.courseDetail(id: 1))
        #expect(refreshed.last?.freshness == .fresh)
        #expect(refreshed.last?.value.lessons.first { $0.id == 103 }?.isCompleted == true)

        // 4. The outbox uploads it.
        await repository.syncPendingChanges()
        #expect(await remote.uploadedCompletions.contains(103))
    }

    @Test("Catalog progress reflects local completions that are still queued")
    func catalogKeepsLocalProgress() async throws {
        _ = try await collect(repository.courses())
        _ = try await collect(repository.courseDetail(id: 2))
        await remote.setOnline(false)
        _ = try await repository.completeLesson(201, inCourse: 2)

        let offlineCatalog = try await collect(repository.courses())
        #expect(offlineCatalog.last?.value.first { $0.id == 2 }?.progress == 50)
    }
}
