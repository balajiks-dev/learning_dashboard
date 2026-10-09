import DataLayer
import Domain
import Foundation
import os
import Presentation
import SwiftData

/// Composition root: the only place that knows concrete types from every
/// layer. Everything else depends on protocols, so swapping the mock backend
/// for a real one means changing one line here.
@MainActor
final class AppContainer {
    let networkMonitor = NetworkMonitor()
    let sessionViewModel: SessionViewModel

    private let authRepository: any AuthRepository
    private let courseRepository: any CourseRepository
    private static let logger = Logger(subsystem: "LearningDashboard", category: "AppContainer")

    init() {
        let sessionStorage = KeychainSessionStorage(service: Bundle.main.bundleIdentifier ?? "LearningDashboard")
        let http: any HTTPClient = Self.makeHTTPClient(connectivity: networkMonitor)
        let apiClient = APIClient(baseURL: AppConfiguration.apiBaseURL, http: http, sessionStorage: sessionStorage)

        authRepository = DefaultAuthRepository(client: apiClient, sessionStorage: sessionStorage)
        courseRepository = DefaultCourseRepository(
            remote: APICourseRemoteDataSource(client: apiClient),
            store: CourseLocalStore(modelContainer: Self.makeModelContainer())
        )
        sessionViewModel = SessionViewModel(
            restoreSession: RestoreSessionUseCase(repository: authRepository),
            logout: LogoutUseCase(authRepository: authRepository, courseRepository: courseRepository)
        )
    }

    // MARK: Screen factories

    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(login: LoginUseCase(repository: authRepository)) { [sessionViewModel] user in
            sessionViewModel.didSignIn(user)
        }
    }

    func makeCourseListViewModel() -> CourseListViewModel {
        let viewModel = CourseListViewModel(
            getCourses: GetCoursesUseCase(repository: courseRepository),
            connectivity: networkMonitor
        )
        viewModel.onSessionExpired = { [sessionViewModel] in
            Task { await sessionViewModel.signOut() }
        }
        return viewModel
    }

    func makeCourseDetailViewModel(course: Course, onCourseUpdated: @escaping @MainActor (Course) -> Void) -> CourseDetailViewModel {
        CourseDetailViewModel(
            course: course,
            getDetail: GetCourseDetailUseCase(repository: courseRepository),
            completeLesson: CompleteLessonUseCase(repository: courseRepository),
            onCourseUpdated: onCourseUpdated
        )
    }

    // MARK: Infrastructure

    private static func makeHTTPClient(connectivity: NetworkMonitor) -> any HTTPClient {
        guard AppConfiguration.usesMockBackend else { return URLSessionHTTPClient() }
        do {
            return MockHTTPClient(backend: try MockBackend(), connectivity: connectivity)
        } catch {
            fatalError("Bundled mock fixtures are missing: \(error)")
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        do {
            return try PersistenceController.makeContainer()
        } catch {
            // A broken on-disk store must not brick the app: run with an
            // in-memory cache for this session and report it.
            logger.error("Falling back to in-memory store: \(error.localizedDescription, privacy: .public)")
            return try! PersistenceController.makeContainer(inMemory: true)
        }
    }
}
