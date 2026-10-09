/// Runs async operations one at a time, in arrival order. Used for outbox
/// syncs so the same pending item is never uploaded twice concurrently.
///
/// Each operation is chained onto the previous one, so there is no polling
/// loop: a waiter can never spin on an already-finished task while starving
/// the actor.
actor SerialTaskQueue {
    private var tail: Task<Void, Never>?

    func run(_ operation: @escaping @Sendable () async -> Void) async {
        let previous = tail
        let task = Task {
            await previous?.value
            await operation()
        }
        tail = task
        await task.value
    }
}
