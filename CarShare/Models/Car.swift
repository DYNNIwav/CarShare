import Foundation

struct Car: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var licensePlate: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Car, rhs: Car) -> Bool {
        lhs.id == rhs.id
    }
} 