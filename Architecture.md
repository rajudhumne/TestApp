# TestApp Architecture

## Architecture decision summary
- SwiftUI with the Observation macro drives the UI; `SessionManager` in the environment gates navigation between `LoginView` and `DashboardView`.
- Local persistence is provided by SQLite (via SQLite.swift) behind repository types (`UserRepository`, `RecordRepository`) to keep schema and queries out of UI code.
- Data is generated locally (`DataGeneratorService`) and written immediately to the local database, enabling an offline-first flow; remote sync is an eventual-consistency background concern handled by `SyncService`.
- AI responses are produced by a local Ollama instance through `OllamaLLM`, which depends on a generic `NetworkService` abstraction over `URLSession`.
- Push delivery is handled by `AppDelegate` (Firebase Messaging). Delivery events are rebroadcast through `NotificationCenter` for UI reactions (e.g., the dashboard indicator).
- Services are injected into `DashboardViewModel` via protocols to keep boundaries testable and allow swapping implementations.
- Concurrency uses Swift async/await with long-lived tasks for the data stream and sync loop; UI-facing mutations are isolated to a `@MainActor` view model.

## Components and responsibilities
- **App shell**: `TestAppApp` wires SwiftUI and injects `SessionManager`; `AppDelegate` configures Firebase/push and forwards notification taps.
- **Session/auth**: `LoginView` creates or authenticates users through `UserRepository` and updates `SessionManager`.
- **Dashboard**: `DashboardView` owns `DashboardViewModel`, renders live records, AI status, controls, and push indicator.
- **Data generation**: `DataGeneratorService` produces `RandomRecord` values on a timed loop, exposed as `AsyncStream`.
- **Persistence**: `LocalDatabaseService` owns the SQLite connection; `UserRepository` and `RecordRepository` encapsulate table schema and CRUD; `RandomRecord`/`User` are domain models.
- **Sync**: `SyncService` polls for unsynced records and marks them synced after (currently mocked) upload, raising `.syncCompleted` notifications.
- **AI**: `OllamaLLM` builds requests with `OllamaEndpoint` and executes them with `NetworkService` to generate short responses.

## Threading model
- **UI/main actor**: `DashboardViewModel` is `@MainActor`; state mutations and UI bindings occur on the main thread. Network calls and DB inserts currently happen from this context; for heavier loads, wrap them in `Task.detached` to avoid blocking the main actor.
- **Data stream**: `DataGeneratorService` starts a `Task` that ticks once per second, yielding records through an `AsyncStream`. The consumer (`DashboardViewModel`) awaits the stream and handles records sequentially.
- **Sync loop**: `SyncService` runs in a detached task with a configurable interval (`syncInterval`, default 100s). It can be cancelled via `stop()`. Errors are logged and the loop continues after a sleep.
- **Networking**: `NetworkService.execute` is async and uses `URLSession` (injectable via protocol) to offload I/O from the caller.
- **Notifications**: Firebase callbacks occur on system-provided threads; the delegate posts `NotificationCenter` events that SwiftUI observes on the main queue.
- **Cancellation**: Long-lived tasks (`streamTask` in `DashboardViewModel`, `task` in `DataGeneratorService` and `SyncService`) store handles and respect `Task.isCancelled`.

## Data flow
```mermaid
flowchart LR
    U[User] -->|login/create| LV[LoginView]
    LV -->|read/write| UR[UserRepository]
    UR --> DB[(SQLite DB)]
    LV -->|userId| SM[SessionManager]
    SM --> DV[DashboardView]
    DV --> VM[DashboardViewModel]
    VM -->|start| DG[DataGeneratorService]
    DG -->|AsyncStream\nRandomRecord| VM
    VM -->|insert| RR[RecordRepository]
    RR --> DB
    VM -->|periodic| AI[OllamaLLM\n(NetworkService)]
    AI --> VM
    VM -->|unsynced fetch| SY[SyncService]
    SY --> RR
    SY -->|NotificationCenter\n.syncCompleted| DV
    AD[AppDelegate\n(Firebase Push)] -->|NotificationCenter\n.didReceiveCloudUpdate| DV
```

## Notes and next steps
- Persisted passwords are currently stored as provided; replace with proper hashing (e.g., scrypt/Argon2) for production.
- Consider moving database writes and sync operations off the main actor to prevent UI stalls during I/O.
- Add real remote upload logic inside `SyncService.performSync()` and surface failures in the UI.

