import Domain

struct LoginRequestDTO: Codable, Sendable {
    let email: String
    let password: String
}

struct LoginResponseDTO: Codable, Sendable {
    let token: String
    let user: UserDTO
}

public struct UserDTO: Codable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let email: String

    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }

    var domain: User { User(id: id, name: name, email: email) }
}
