# Learning Dashboard (iOS)

A SwiftUI app (iOS 17+, Swift 6) built with Clean Architecture + MVVM: Domain, Data and Presentation are separate Swift package modules, so the layer rules are enforced by the compiler. Courses are cached in SwiftData so they stay available offline, lesson completions are saved locally and synced when back online, and the auth token is stored in the Keychain. Open `LearningDashboard.xcworkspace`, run the **LearningDashboard** scheme, sign in with `learner@example.com` / `password123`, and press ⌘U to run the tests.
