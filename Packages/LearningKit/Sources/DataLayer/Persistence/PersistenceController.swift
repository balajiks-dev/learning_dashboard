import SwiftData

public enum PersistenceController {
    public static func makeContainer(inMemory: Bool = false) throws -> ModelContainer {
        let schema = Schema([
            CourseRecord.self,
            LessonRecord.self,
            PendingCompletionRecord.self,
            SyncMarkerRecord.self,
        ])
        let configuration = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration("LearningDashboard", schema: schema)
        return try ModelContainer(for: schema, configurations: configuration)
    }
}
