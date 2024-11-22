import Foundation

struct Trip: Identifiable, Codable {
    let id: UUID
    let car: Car
    let date: Date
    let kilometers: Double
    let description: String
    let participants: Set<User>
    let isOsloArea: Bool
    let totalPrice: Double
    
    init(id: UUID = UUID(), car: Car, date: Date, kilometers: Double, description: String, participants: Set<User>, isOsloArea: Bool) {
        self.id = id
        self.car = car
        self.date = date
        self.kilometers = kilometers
        self.description = description
        self.participants = participants
        self.isOsloArea = isOsloArea
        self.totalPrice = Zone.calculatePrice(kilometers: kilometers, isOsloArea: isOsloArea)
    }
} 