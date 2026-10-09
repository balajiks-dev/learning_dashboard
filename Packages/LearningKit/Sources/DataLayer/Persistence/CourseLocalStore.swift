import Domain
import Foundation
import SwiftData

public struct PendingCompletion: Equatable, Sendable {
    public let lessonID: Int
    public let courseID: Int
}

enum PersistenceError: Error, Equatable {
    case courseNotCached
    case lessonNotCached
}

/// The offline cache. A `ModelActor`, so every SwiftData access runs on one
/// serial background executor; callers only ever receive Sendable domain values.
public actor CourseLocalStore: ModelActor {
    public nonisolated let modelContainer: ModelContainer
    public nonisolated let modelExecutor: any ModelExecutor

    private static let catalogMarker = "catalog"

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
    }

    // MARK: Catalog

    /// `nil` when the catalog has never been downloaded on this device.
    func cachedCourses() throws -> (courses: [Course], syncedAt: Date)? {
        guard let marker = try marker(Self.catalogMarker) else { return nil }
        return (try allCourses(), marker.syncedAt)
    }

    /// Upserts the catalog. Lesson completion only ever moves forward, so a
    /// course's progress is never lowered by a server copy that hasn't yet
    /// received this device's offline completions.
    func saveCatalog(_ dtos: [CourseDTO], syncedAt: Date) throws -> [Course] {
        var existing = Dictionary(
            uniqueKeysWithValues: try modelContext.fetch(FetchDescriptor<CourseRecord>()).map { ($0.courseID, $0) }
        )
        for (position, dto) in dtos.enumerated() {
            if let record = existing.removeValue(forKey: dto.id) {
                record.title = dto.title
                record.instructor = dto.instructor
                record.position = position
                if record.lessons.isEmpty {
                    record.progress = dto.progress
                    record.lessonCount = dto.lessons
                } else {
                    record.progress = max(dto.progress, record.detail.progress)
                }
            } else {
                modelContext.insert(CourseRecord(
                    courseID: dto.id, title: dto.title, instructor: dto.instructor,
                    progress: dto.progress, lessonCount: dto.lessons, position: position
                ))
            }
        }
        existing.values.forEach(modelContext.delete)
        try upsertMarker(Self.catalogMarker, syncedAt: syncedAt)
        try modelContext.save()
        return try allCourses()
    }

    // MARK: Course detail

    /// `nil` when this course's lessons have never been downloaded.
    func cachedDetail(courseID: Int) throws -> (detail: CourseDetail, syncedAt: Date)? {
        guard let course = try course(courseID), let syncedAt = course.lessonsSyncedAt else { return nil }
        return (course.detail, syncedAt)
    }

    /// Merges server lessons into the cache. A lesson stays completed if
    /// either side says so, so offline completions survive a refresh.
    func saveLessons(_ dtos: [LessonDTO], courseID: Int, syncedAt: Date) throws -> CourseDetail {
        guard let course = try course(courseID) else { throw PersistenceError.courseNotCached }

        var existing = Dictionary(uniqueKeysWithValues: course.lessons.map { ($0.lessonID, $0) })
        for dto in dtos {
            if let record = existing.removeValue(forKey: dto.id) {
                record.title = dto.title
                record.position = dto.order
                record.isCompleted = record.isCompleted || dto.completed
            } else {
                course.lessons.append(LessonRecord(
                    lessonID: dto.id, title: dto.title, position: dto.order, isCompleted: dto.completed
                ))
            }
        }
        existing.values.forEach(modelContext.delete)

        let detail = course.detail
        course.progress = detail.progress
        course.lessonCount = detail.lessons.count
        course.lessonsSyncedAt = syncedAt
        try modelContext.save()
        return detail
    }

    /// Applies the domain rule, persists it and records an outbox entry, all in
    /// one save, so the UI state and the upload queue can't disagree.
    func markLessonCompleted(_ lessonID: Int, courseID: Int, at date: Date) throws -> CourseDetail {
        guard let course = try course(courseID) else { throw PersistenceError.courseNotCached }
        guard let lesson = course.lessons.first(where: { $0.lessonID == lessonID }) else {
            throw PersistenceError.lessonNotCached
        }
        guard !lesson.isCompleted else { return course.detail }

        let updated = try course.detail.markingLessonCompleted(lessonID)
        lesson.isCompleted = true
        course.progress = updated.progress
        if try pendingCompletion(lessonID) == nil {
            modelContext.insert(PendingCompletionRecord(lessonID: lessonID, courseID: courseID, createdAt: date))
        }
        try modelContext.save()
        return updated
    }

    // MARK: Outbox

    func pendingCompletions() throws -> [PendingCompletion] {
        let descriptor = FetchDescriptor<PendingCompletionRecord>(sortBy: [SortDescriptor(\.createdAt)])
        return try modelContext.fetch(descriptor).map {
            PendingCompletion(lessonID: $0.lessonID, courseID: $0.courseID)
        }
    }

    func removePendingCompletion(lessonID: Int) throws {
        guard let record = try pendingCompletion(lessonID) else { return }
        modelContext.delete(record)
        try modelContext.save()
    }

    // MARK: Housekeeping

    func clearAll() throws {
        try modelContext.delete(model: LessonRecord.self)
        try modelContext.delete(model: CourseRecord.self)
        try modelContext.delete(model: PendingCompletionRecord.self)
        try modelContext.delete(model: SyncMarkerRecord.self)
        try modelContext.save()
    }

    // MARK: Private helpers

    private func allCourses() throws -> [Course] {
        let descriptor = FetchDescriptor<CourseRecord>(sortBy: [SortDescriptor(\.position)])
        return try modelContext.fetch(descriptor).map(\.domain)
    }

    private func course(_ courseID: Int) throws -> CourseRecord? {
        var descriptor = FetchDescriptor<CourseRecord>(predicate: #Predicate { $0.courseID == courseID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func pendingCompletion(_ lessonID: Int) throws -> PendingCompletionRecord? {
        var descriptor = FetchDescriptor<PendingCompletionRecord>(predicate: #Predicate { $0.lessonID == lessonID })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func marker(_ key: String) throws -> SyncMarkerRecord? {
        var descriptor = FetchDescriptor<SyncMarkerRecord>(predicate: #Predicate { $0.key == key })
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func upsertMarker(_ key: String, syncedAt: Date) throws {
        if let existing = try marker(key) {
            existing.syncedAt = syncedAt
        } else {
            modelContext.insert(SyncMarkerRecord(key: key, syncedAt: syncedAt))
        }
    }
}

private extension CourseRecord {
    var domain: Course {
        Course(id: courseID, title: title, instructor: instructor, progress: progress, lessonCount: lessonCount)
    }

    var detail: CourseDetail {
        CourseDetail(course: domain, lessons: lessons.map {
            Lesson(id: $0.lessonID, courseID: courseID, title: $0.title, position: $0.position, isCompleted: $0.isCompleted)
        })
    }
}
