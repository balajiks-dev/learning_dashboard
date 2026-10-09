import Presentation
import SwiftUI

/// Tells the user, honestly, how fresh the data on screen is.
struct SyncStatusBanner: View {
    let status: SyncStatus
    let isConnected: Bool

    var body: some View {
        if let content {
            Label {
                Text(content.message)
                    .font(.footnote.weight(.medium))
            } icon: {
                Image(systemName: content.icon)
            }
            .foregroundStyle(content.tint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(content.tint.opacity(0.12), in: .rect(cornerRadius: 12))
            .accessibilityElement(children: .combine)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var content: (icon: String, message: String, tint: Color)? {
        switch status {
        case .offline(let lastSynced):
            ("wifi.slash", "You're offline · showing saved data\(Self.suffix(lastSynced))", .orange)
        case .refreshFailed(let lastSynced):
            ("exclamationmark.arrow.triangle.2.circlepath", "Couldn't refresh · showing saved data\(Self.suffix(lastSynced))", .orange)
        case .upToDate, .refreshing:
            isConnected ? nil : ("wifi.slash", "You're offline · changes will sync when you reconnect", .orange)
        }
    }

    private static func suffix(_ date: Date?) -> String {
        guard let date else { return "" }
        return " from " + date.formatted(.relative(presentation: .named))
    }
}
