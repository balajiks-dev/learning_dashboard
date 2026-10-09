import SwiftUI

struct ProgressRing: View {
    let progress: Int
    var lineWidth: CGFloat = 6
    var showsLabel = true

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.progressTint(for: progress).opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(progress) / 100)
                .stroke(Color.progressTint(for: progress), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: progress)
            if showsLabel {
                Text("\(progress)%")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(progress)))
                    .animation(.default, value: progress)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue("\(progress) percent")
    }
}

extension Color {
    static func progressTint(for progress: Int) -> Color {
        switch progress {
        case 100...: .green
        case 50..<100: .accentColor
        case 1..<50: .orange
        default: .secondary
        }
    }
}

#Preview {
    HStack(spacing: 24) {
        ProgressRing(progress: 0).frame(width: 52, height: 52)
        ProgressRing(progress: 25).frame(width: 52, height: 52)
        ProgressRing(progress: 65).frame(width: 52, height: 52)
        ProgressRing(progress: 100).frame(width: 52, height: 52)
    }
    .padding()
}
