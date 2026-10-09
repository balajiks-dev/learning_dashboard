import Foundation

public struct Endpoint: Sendable {
    public enum Method: String, Sendable {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
    }

    let path: String
    let method: Method
    let body: Data?
    let requiresAuth: Bool

    init(path: String, method: Method = .get, body: Data? = nil, requiresAuth: Bool = true) {
        self.path = path
        self.method = method
        self.body = body
        self.requiresAuth = requiresAuth
    }
}

extension Endpoint {
    static func login(email: String, password: String) throws -> Endpoint {
        let body = try JSONEncoder().encode(LoginRequestDTO(email: email, password: password))
        return Endpoint(path: "auth/login", method: .post, body: body, requiresAuth: false)
    }

    static let courses = Endpoint(path: "courses")

    static func lessons(courseID: Int) -> Endpoint {
        Endpoint(path: "courses/\(courseID)/lessons")
    }

    /// PUT, not POST: marking a lesson complete is idempotent, so the offline
    /// queue can safely retry it.
    static func completeLesson(_ lessonID: Int, courseID: Int) -> Endpoint {
        Endpoint(path: "courses/\(courseID)/lessons/\(lessonID)/completion", method: .put)
    }
}
