import Domain
import Presentation
import SwiftUI

struct CourseListView: View {
    @State private var viewModel: CourseListViewModel
    @State private var path: [Course] = []
    @State private var isConfirmingSignOut = false
    let user: User
    let container: AppContainer

    init(viewModel: CourseListViewModel, user: User, container: AppContainer) {
        _viewModel = State(initialValue: viewModel)
        self.user = user
        self.container = container
    }

    var body: some View {
        NavigationStack(path: $path) {
            content
                .navigationTitle("My Courses")
                .toolbar { accountMenu }
                .navigationDestination(for: Course.self) { course in
                    CourseDetailView(viewModel: container.makeCourseDetailViewModel(
                        course: course,
                        onCourseUpdated: viewModel.courseDidChange
                    ))
                }
                .background(Color(.systemGroupedBackground))
        }
        // Attached to the stack (not the root content) so pushing a detail
        // screen doesn't cancel an in-flight load.
        .task { await viewModel.loadIfNeeded() }
        .task { await viewModel.observeConnectivity() }
        .confirmationDialog("Sign out?", isPresented: $isConfirmingSignOut, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { await container.sessionViewModel.signOut() }
            }
        } message: {
            Text("Downloaded courses will be removed from this device.")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            CourseListSkeleton()
        case .empty:
            ScrollView {
                ContentUnavailableView {
                    Label("No courses yet", systemImage: "books.vertical")
                } description: {
                    Text("Courses you enroll in will appear here.")
                } actions: {
                    Button("Refresh") { Task { await viewModel.load() } }
                }
                .padding(.top, 80)
            }
            .refreshable { await viewModel.load() }
        case .failed(let error):
            ErrorStateView(error: error, retry: viewModel.load)
        case .loaded(let courses):
            courseList(courses)
        }
    }

    private func courseList(_ courses: [Course]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                SyncStatusBanner(status: viewModel.syncStatus, isConnected: viewModel.isConnected)
                OverviewCard(user: user, courses: courses, overallProgress: viewModel.overallProgress)
                ForEach(courses) { course in
                    CourseCard(course: course) { path.append(course) }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
            .animation(.default, value: viewModel.syncStatus)
            .animation(.default, value: viewModel.isConnected)
        }
        .refreshable { await viewModel.load() }
    }

    private var accountMenu: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section(user.email) {
                    #if DEBUG
                    Toggle(isOn: Binding(
                        get: { container.networkMonitor.isSimulatingOffline },
                        set: { container.networkMonitor.isSimulatingOffline = $0 }
                    )) {
                        Label("Simulate Offline", systemImage: "wifi.slash")
                    }
                    #endif
                    Button(role: .destructive) {
                        isConfirmingSignOut = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            } label: {
                Text(user.name.prefix(1).uppercased())
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.gradient, in: .circle)
            }
            .accessibilityLabel("Account")
        }
    }
}

private struct OverviewCard: View {
    let user: User
    let courses: [Course]
    let overallProgress: Int

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Hi, \(user.name) 👋")
                    .font(.title3.bold())
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            ProgressRing(progress: overallProgress, lineWidth: 7)
                .frame(width: 60, height: 60)
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
    }

    private var summary: String {
        let inProgress = courses.filter { $0.isStarted && !$0.isFinished }.count
        return "\(courses.count) courses · \(inProgress) in progress"
    }
}

private struct CourseListSkeleton: View {
    private let placeholder = Course(id: 0, title: "Loading course title", instructor: "Instructor name", progress: 40, lessonCount: 20)

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    CourseCard(course: placeholder) {}
                }
            }
            .padding(.horizontal)
        }
        .redacted(reason: .placeholder)
        .disabled(true)
        .accessibilityLabel("Loading courses")
    }
}
