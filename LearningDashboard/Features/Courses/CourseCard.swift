import Domain
import SwiftUI

struct CourseCard: View {
    let course: Course
    let onContinue: () -> Void

    var body: some View {
        Button(action: onContinue) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: icon)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.tint)
                        .frame(width: 46, height: 46)
                        .background(.tint.opacity(0.12), in: .rect(cornerRadius: 12))
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(course.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Label(course.instructor, systemImage: "person.fill")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Label("\(course.lessonCount) lessons", systemImage: "list.bullet.rectangle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                VStack(spacing: 6) {
                    HStack {
                        Text("Progress")
                        Spacer()
                        Text("\(course.progress)%")
                            .fontWeight(.semibold)
                            .monospacedDigit()
                            .contentTransition(.numericText(value: Double(course.progress)))
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    ProgressView(value: Double(course.progress), total: 100)
                        .tint(Color.progressTint(for: course.progress))
                        .animation(.spring, value: course.progress)
                }

                HStack {
                    Spacer()
                    Text(callToAction)
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(.tint, in: .capsule)
                }
            }
            .padding(18)
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 20))
            .contentShape(.rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the course lessons")
    }

    private var callToAction: String {
        if course.isFinished { "Review" } else if course.isStarted { "Continue" } else { "Start" }
    }

    private var icon: String {
        switch course.title.lowercased() {
        case let title where title.contains("python"): "chevron.left.forwardslash.chevron.right"
        case let title where title.contains("ai"): "sparkles"
        case let title where title.contains("stack") || title.contains("web"): "square.stack.3d.up"
        default: "book.closed"
        }
    }
}
