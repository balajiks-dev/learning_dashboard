import Domain
import Foundation

/// A tiny stateful fake of the course API, seeded from bundled JSON fixtures.
/// It keeps lesson completions in memory, so progress uploaded by the offline
/// queue is reflected in later responses, like a real server would.
public actor MockBackend {
    public static let demoEmail = "learner@example.com"
    public static let demoPassword = "password123"

    private var courses: [CourseDTO]
    private var lessons: [Int: [LessonDTO]]
    private let encoder = JSONEncoder()

    public init() throws {
        try self.init(bundle: .module)
    }

    init(bundle: Bundle) throws {
        let decoder = JSONDecoder()
        let courses = try decoder.decode([CourseDTO].self, from: Self.fixture("courses", in: bundle))
        let lessonsByKey = try decoder.decode([String: [LessonDTO]].self, from: Self.fixture("lessons", in: bundle))
        let lessons = Dictionary(uniqueKeysWithValues: lessonsByKey.compactMap { key, value in
            Int(key).map { ($0, value) }
        })
        self.lessons = lessons
        // Derive progress from lessons so the catalog and details always agree.
        self.courses = courses.map { Self.withDerivedProgress($0, lessons: lessons[$0.id]) }
    }

    func handle(_ request: URLRequest) -> (status: Int, body: Data) {
        let segments = request.url?.pathComponents.filter { $0 != "/" } ?? []
        let method = request.httpMethod ?? "GET"
        let path = Array(segments.drop { $0 != "auth" && $0 != "courses" })

        if method == "POST", path == ["auth", "login"] {
            return login(body: request.httpBody)
        }
        guard request.value(forHTTPHeaderField: "Authorization")?.hasPrefix("Bearer ") == true else {
            return error(401, "Missing or invalid token.")
        }

        switch (method, path.count) {
        case ("GET", 1) where path == ["courses"]:
            return ok(courses)
        case ("GET", 3) where path[0] == "courses" && path[2] == "lessons":
            guard let id = Int(path[1]), let lessons = lessons[id] else { return error(404, "Course not found.") }
            return ok(lessons)
        case ("PUT", 5) where path[0] == "courses" && path[2] == "lessons" && path[4] == "completion":
            guard let courseID = Int(path[1]), let lessonID = Int(path[3]),
                  let index = lessons[courseID]?.firstIndex(where: { $0.id == lessonID })
            else { return error(404, "Lesson not found.") }
            lessons[courseID]?[index].completed = true
            recalculateProgress(courseID: courseID)
            return (204, Data())
        default:
            return error(404, "No route for \(method) /\(path.joined(separator: "/")).")
        }
    }

    private func login(body: Data?) -> (status: Int, body: Data) {
        guard let body, let credentials = try? JSONDecoder().decode(LoginRequestDTO.self, from: body) else {
            return error(400, "Malformed request.")
        }
        guard credentials.password == Self.demoPassword else {
            return error(401, "Invalid email or password.")
        }
        let name = credentials.email.split(separator: "@").first.map { $0.capitalized } ?? "Learner"
        return ok(LoginResponseDTO(
            token: "mock.\(UUID().uuidString)",
            user: UserDTO(id: "u_001", name: name, email: credentials.email)
        ))
    }

    private func recalculateProgress(courseID: Int) {
        guard let index = courses.firstIndex(where: { $0.id == courseID }) else { return }
        courses[index] = Self.withDerivedProgress(courses[index], lessons: lessons[courseID])
    }

    private static func withDerivedProgress(_ course: CourseDTO, lessons: [LessonDTO]?) -> CourseDTO {
        guard let lessons, !lessons.isEmpty else { return course }
        var course = course
        let completed = lessons.filter(\.completed).count
        course.progress = ProgressCalculator.percentage(completed: completed, total: lessons.count)
        course.lessons = lessons.count
        return course
    }

    private func ok(_ value: some Encodable) -> (status: Int, body: Data) {
        (200, (try? encoder.encode(value)) ?? Data())
    }

    private func error(_ status: Int, _ message: String) -> (status: Int, body: Data) {
        (status, (try? encoder.encode(["message": message])) ?? Data())
    }

    private static func fixture(_ name: String, in bundle: Bundle) throws -> Data {
        guard let url = bundle.url(forResource: name, withExtension: "json")
            ?? bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")
        else { throw CocoaError(.fileNoSuchFile) }
        return try Data(contentsOf: url)
    }
}
