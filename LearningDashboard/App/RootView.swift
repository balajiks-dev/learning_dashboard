import Presentation
import SwiftUI

/// Switches between launch, login and the main flow based on the session phase.
struct RootView: View {
    let container: AppContainer

    var body: some View {
        let session = container.sessionViewModel
        Group {
            switch session.phase {
            case .launching:
                LaunchView()
            case .signedOut:
                LoginView(viewModel: container.makeLoginViewModel())
                    .transition(.opacity)
            case .signedIn(let user):
                CourseListView(
                    viewModel: container.makeCourseListViewModel(),
                    user: user,
                    container: container
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: session.phase)
        .task { await session.restore() }
    }
}

private struct LaunchView: View {
    var body: some View {
        ProgressView()
            .controlSize(.large)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
    }
}
