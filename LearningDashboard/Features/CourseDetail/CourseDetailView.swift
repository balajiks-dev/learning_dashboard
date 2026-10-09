import Domain
import Presentation
import SwiftUI

struct CourseDetailView: View {
    @State private var viewModel: CourseDetailViewModel

    init(viewModel: CourseDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                CourseHeader(course: viewModel.course, completed: viewModel.state.value?.completedCount)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if viewModel.syncStatus.isStale {
                SyncStatusBanner(status: viewModel.syncStatus, isConnected: true)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            lessonsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.course.title)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await viewModel.load() }
        .task { await viewModel.load() }
        .sensoryFeedback(.success, trigger: viewModel.state.value?.completedCount)
        .alert(
            viewModel.alert?.title ?? "",
            isPresented: Binding(get: { viewModel.alert != nil }, set: { if !$0 { viewModel.alert = nil } }),
            presenting: viewModel.alert
        ) { _ in
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.userMessage)
        }
    }

    @ViewBuilder
    private var lessonsSection: some View {
        switch viewModel.state {
        case .idle, .loading:
            Section("Lessons") {
                ForEach(0..<5, id: \.self) { index in
                    LessonRow(
                        lesson: Lesson(id: -index, courseID: 0, title: "Loading lesson title", position: index + 1, isCompleted: false),
                        isCompleting: false,
                        onComplete: {}
                    )
                }
            }
            .redacted(reason: .placeholder)
        case .failed(let error):
            Section {
                ErrorStateView(error: error, retry: viewModel.load)
            }
        case .empty:
            Section {
                ContentUnavailableView("No lessons yet", systemImage: "list.bullet.rectangle")
            }
        case .loaded(let detail):
            Section {
                ForEach(detail.lessons) { lesson in
                    LessonRow(
                        lesson: lesson,
                        isCompleting: viewModel.completingLessonIDs.contains(lesson.id),
                        onComplete: { Task { await viewModel.complete(lesson) } }
                    )
                }
            } header: {
                Text("Lessons")
            } footer: {
                if let next = detail.nextLesson {
                    Text("Up next: \(next.title)")
                } else {
                    Text("You've completed every lesson. 🎉")
                }
            }
        }
    }
}

private struct CourseHeader: View {
    let course: Course
    let completed: Int?

    var body: some View {
        HStack(spacing: 20) {
            ProgressRing(progress: course.progress, lineWidth: 9)
                .frame(width: 88, height: 88)
            VStack(alignment: .leading, spacing: 6) {
                Text(course.title)
                    .font(.title2.bold())
                Label(course.instructor, systemImage: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(completedText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.progressTint(for: course.progress))
                    .contentTransition(.numericText())
                    .animation(.default, value: completed)
            }
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
        .padding(.vertical, 8)
    }

    private var completedText: String {
        guard let completed else { return "\(course.lessonCount) lessons" }
        return "\(completed) of \(course.lessonCount) lessons completed"
    }
}

private struct LessonRow: View {
    let lesson: Lesson
    let isCompleting: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(lesson.isCompleted ? Color.green : Color(.tertiarySystemFill))
                if lesson.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    Text("\(lesson.position)")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 30, height: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(lesson.title)
                    .font(.body)
                Text(lesson.isCompleted ? "✓ Completed" : "○ Pending")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(lesson.isCompleted ? .green : .secondary)
            }

            Spacer(minLength: 8)

            if !lesson.isCompleted {
                Button(action: onComplete) {
                    if isCompleting {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Mark done")
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(isCompleting)
                .accessibilityLabel("Mark \(lesson.title) as completed")
            }
        }
        .padding(.vertical, 4)
        .animation(.spring(duration: 0.35), value: lesson.isCompleted)
        .swipeActions(edge: .trailing) {
            if !lesson.isCompleted {
                Button("Complete", systemImage: "checkmark", action: onComplete)
                    .tint(.green)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
