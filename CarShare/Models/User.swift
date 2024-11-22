import Foundation

struct User: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    
    static let users = [
        User(id: UUID(), name: "Charlotte"),
        User(id: UUID(), name: "Johanne"),
        User(id: UUID(), name: "Julius"),
        User(id: UUID(), name: "Pål")
    ]
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }
} 