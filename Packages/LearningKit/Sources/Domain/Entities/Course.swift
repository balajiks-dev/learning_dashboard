public struct Course: Identifiable, Hashable, Sendable {
    public let id: Int
    public let title: String
    public let instructor: String
    /// Completion percentage in the range 0...100.
    public let progress: Int
    public let lessonCount: Int

    public init(id: Int, title: String, instructor: String, progress: Int, lessonCount: Int) {
        self.id = id
        self.title = title
        self.instructor = instructor
        self.progress = min(max(progress, 0), 100)
        self.lessonCount = max(lessonCount, 0)
    }

    public var isStarted: Bool { progress > 0 }
    public var isFinished: Bool { progress >= 100 }

    func updating(progress: Int, lessonCount: Int) -> Course {
        Course(id: id, title: title, instructor: instructor, progress: progress, lessonCount: lessonCount)
    }
}
