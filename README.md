# Learning Dashboard — iOS (Swift 6 · SwiftUI · Clean Architecture)

Login → Course Dashboard → Course Details with lesson completion, offline-first.
**Run:** open `LearningDashboard.xcworkspace`, scheme **LearningDashboard**, iOS 17+ simulator. **Demo login:** `learner@example.com` / `password123` (or tap *Use demo account*).
**Tests:** `⌘U` in Xcode, or `cd Packages/LearningKit && swift test` (28 tests, Swift Testing).
**Offline demo:** load courses → avatar menu → *Simulate Offline* (DEBUG), or turn off the Mac's Wi-Fi → relaunch / pull to refresh.

## 1. Architecture
Clean Architecture + MVVM. **Each layer is its own Swift Package module, so the dependency rule is enforced by the compiler**, not by convention:

```
App (SwiftUI views + AppContainer composition root)
 ├─▶ Presentation  @Observable ViewModels, LoadState/SyncStatus      ─┐
 └─▶ DataLayer     APIClient, SwiftData store, Keychain, repositories ─┴─▶ Domain (entities, use cases, repository protocols — no dependencies)
```
- **Domain** holds the business rules as pure, tested code (`ProgressCalculator`, `CourseDetail.markingLessonCompleted`, `CredentialsValidator`).
- **Presentation** can't import SwiftData or networking. ViewModels expose one `LoadState` enum (idle/loading/loaded/empty/failed), so impossible state combinations can't be represented, and they're unit-tested on macOS without a simulator.
- **DataLayer** maps DTOs ↔ entities and transport/persistence errors → `DomainError`. `HTTPClient` is the only transport seam: the demo uses `MockHTTPClient` (an in-process stateful fake server that respects real connectivity); production swaps in `URLSessionHTTPClient` with one line in `AppContainer`.
- Swift 6 strict concurrency throughout: UI state is `@MainActor`, SwiftData lives behind a `ModelActor`, and only `Sendable` values cross boundaries.

I chose this because it keeps features testable in isolation, keeps a backend change inside one layer, and lets a team work on layers in parallel.

## 2. Offline support
- **Store:** SwiftData (`CourseLocalStore`, a `ModelActor`). Courses, lessons, a sync marker, and an outbox of pending completions.
- **Read policy, cache-then-network** (`cacheThenNetwork`): emit the cached data instantly, fetch, persist, emit `.fresh`. If the fetch fails, re-emit the cache as `.stale(reason:)` and show a banner (“You're offline · showing saved data from 5 min ago”). Fail only if nothing was ever cached.
- **Writes are local-first:** completing a lesson updates SwiftData and adds an outbox entry in one save, so it works offline. A serial queue uploads the outbox with an idempotent `PUT`: right away when possible, otherwise before every refresh and when connectivity returns.
- **Conflict rule:** completion is monotonic (`local || remote`), so a refresh can never undo progress the server hasn't received yet.

## 3. Security (tokens)
In the **Keychain** (`KeychainSessionStorage`, `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`): never in UserDefaults or plain files, and excluded from backups and device migration. In production I'd also use a short-lived access token with a refresh token, handle 401s centrally (already mapped to `sessionExpired` → sign out), use ATS/TLS with certificate pinning for the API domain, enable Data Protection on the SQLite store, and wipe the cache on logout (already done in `LogoutUseCase`).

## 4. Scale (1M users, hundreds of courses)
1. **Pagination and delta sync:** cursor-paged `/courses`, `ETag`/`If-Modified-Since` and `updatedAt` deltas instead of full downloads, plus HTTP caching through a CDN.
2. **A real sync engine:** retry the outbox with exponential backoff using `BGTaskScheduler`; server-side idempotency keys; batched progress uploads.
3. **Modularise by feature** (Auth, Catalog, Player…) on top of the layered packages; add a design-system package; use a typed router and deep links.
4. **Observability:** structured logging, MetricKit, crash reporting, API latency and error dashboards, feature flags and staged rollouts.
5. **Performance and quality:** image/content prefetching, store indices and migrations (`VersionedSchema`), UI and snapshot tests in CI, accessibility and localisation.

## 5. Second platform: Android
Same layering as Gradle modules (`:domain` pure Kotlin, `:data`, `:presentation`, `:app`): Kotlin Coroutines and `Flow` in place of `AsyncStream`, Jetpack Compose UI, `ViewModel` + `StateFlow<UiState>` (sealed class), Hilt for DI, Retrofit/OkHttp (+ an interceptor for the token), Room for the cache with the same cache-then-network `Flow`, WorkManager for the outbox sync, `ConnectivityManager.NetworkCallback` for connectivity, and EncryptedSharedPreferences/Keystore for tokens. Domain rules and tests port almost line for line.
