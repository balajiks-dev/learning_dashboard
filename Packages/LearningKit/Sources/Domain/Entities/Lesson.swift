public struct Lesson: Identifiable, Hashable, Sendable {
    public let id: Int
    public let courseID: Course.ID
    public let title: String
    /// 1-based position of the lesson inside its course.
    public let position: Int
    public let isCompleted: Bool

    public init(id: Int, courseID: Course.ID, title: String, position: Int, isCompleted: Bool) {
        self.id = id
        self.courseID = courseID
        self.title = title
        self.position = position
        self.isCompleted = isCompleted
    }

    func markedCompleted() -> Lesson {
        Lesson(id: id, courseID: courseID, title: title, position: position, isCompleted: true)
    }
}
