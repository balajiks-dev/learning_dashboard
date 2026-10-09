import Domain

/// Wire format, kept separate from domain entities so API changes stay
/// contained in the data layer.
public struct CourseDTO: Codable, Equatable, Sendable {
    public var id: Int
    public var title: String
    public var instructor: String
    public var progress: Int
    public var lessons: Int

    public init(id: Int, title: String, instructor: String, progress: Int, lessons: Int) {
        self.id = id
        self.title = title
        self.instructor = instructor
        self.progress = progress
        self.lessons = lessons
    }
}

public struct LessonDTO: Codable, Equatable, Sendable {
    public var id: Int
    public var title: String
    public var order: Int
    public var completed: Bool

    public init(id: Int, title: String, order: Int, completed: Bool) {
        self.id = id
        self.title = title
        self.order = order
        self.completed = completed
    }
}
