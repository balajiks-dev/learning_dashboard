import Domain
import Presentation
import SwiftUI

struct ErrorStateView: View {
    let error: DomainError
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label(error.title, systemImage: error == .offline ? "wifi.slash" : "exclamationmark.triangle")
        } description: {
            Text(error.userMessage)
        } actions: {
            Button("Try Again") { Task { await retry() } }
                .buttonStyle(.borderedProminent)
        }
    }
}
