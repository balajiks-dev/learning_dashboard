import Foundation
import SwiftData

// SwiftData models are persistence details: they never leave CourseLocalStore,
// which hands out immutable, Sendable domain structs instead.

@Model
final class CourseRecord {
    @Attribute(.unique) var courseID: Int
    var title: String
    var instructor: String
    var progress: Int
    var lessonCount: Int
    /// Position in the server-provided catalog order.
    var position: Int
    /// `nil` until the lessons for this course have been downloaded once.
    var lessonsSyncedAt: Date?
    @Relationship(deleteRule: .cascade, inverse: \LessonRecord.course)
    var lessons: [LessonRecord] = []

    init(courseID: Int, title: String, instructor: String, progress: Int, lessonCount: Int, position: Int) {
        self.courseID = courseID
        self.title = title
        self.instructor = instructor
        self.progress = progress
        self.lessonCount = lessonCount
        self.position = position
    }
}

@Model
final class LessonRecord {
    @Attribute(.unique) var lessonID: Int
    var title: String
    var position: Int
    var isCompleted: Bool
    var course: CourseRecord?

    init(lessonID: Int, title: String, position: Int, isCompleted: Bool) {
        self.lessonID = lessonID
        self.title = title
        self.position = position
        self.isCompleted = isCompleted
    }
}

/// Outbox entry: a completion made locally that the server hasn't confirmed.
@Model
final class PendingCompletionRecord {
    @Attribute(.unique) var lessonID: Int
    var courseID: Int
    var createdAt: Date

    init(lessonID: Int, courseID: Int, createdAt: Date) {
        self.lessonID = lessonID
        self.courseID = courseID
        self.createdAt = createdAt
    }
}

/// Remembers when a dataset was last synced. Its presence also distinguishes
/// "never downloaded" from "downloaded, and the server returned nothing".
@Model
final class SyncMarkerRecord {
    @Attribute(.unique) var key: String
    var syncedAt: Date

    init(key: String, syncedAt: Date) {
        self.key = key
        self.syncedAt = syncedAt
    }
}
