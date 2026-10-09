import Foundation

enum AppConfiguration {
    /// In a real app this comes from an .xcconfig per build configuration.
    static let apiBaseURL = URL(string: "https://api.learning-dashboard.example.com/v1")!

    /// The demo build ships with an in-process mock backend.
    static let usesMockBackend = true
}
