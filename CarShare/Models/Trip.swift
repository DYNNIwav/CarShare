import Foundation
import CoreLocation

struct Trip: Identifiable, Codable, Equatable {
    var id: UUID
    var car: Car
    var date: Date
    var kilometers: Double
    var description: String
    var participants: Set<User>
    var isOsloArea: Bool
    var totalPrice: Double
    
    var isUsingRoute: Bool
    var startLocation: Location?
    var endLocation: Location?
    var selectedZone: Zone
    
    static func == (lhs: Trip, rhs: Trip) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: CodingKey {
        case id, car, date, kilometers, description, participants, isOsloArea, totalPrice
        case isUsingRoute, startLocation, endLocation, selectedZone
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        car = try container.decode(Car.self, forKey: .car)
        date = try container.decode(Date.self, forKey: .date)
        kilometers = try container.decode(Double.self, forKey: .kilometers)
        description = try container.decode(String.self, forKey: .description)
        participants = try container.decode(Set<User>.self, forKey: .participants)
        isOsloArea = try container.decode(Bool.self, forKey: .isOsloArea)
        totalPrice = try container.decode(Double.self, forKey: .totalPrice)
        isUsingRoute = try container.decode(Bool.self, forKey: .isUsingRoute)
        startLocation = try container.decodeIfPresent(Location.self, forKey: .startLocation)
        endLocation = try container.decodeIfPresent(Location.self, forKey: .endLocation)
        selectedZone = try container.decode(Zone.self, forKey: .selectedZone)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(car, forKey: .car)
        try container.encode(date, forKey: .date)
        try container.encode(kilometers, forKey: .kilometers)
        try container.encode(description, forKey: .description)
        try container.encode(participants, forKey: .participants)
        try container.encode(isOsloArea, forKey: .isOsloArea)
        try container.encode(totalPrice, forKey: .totalPrice)
        try container.encode(isUsingRoute, forKey: .isUsingRoute)
        try container.encodeIfPresent(startLocation, forKey: .startLocation)
        try container.encodeIfPresent(endLocation, forKey: .endLocation)
        try container.encode(selectedZone, forKey: .selectedZone)
    }
    
    init(id: UUID = UUID(), 
         car: Car, 
         date: Date, 
         kilometers: Double, 
         description: String, 
         participants: Set<User>, 
         isOsloArea: Bool,
         isUsingRoute: Bool = false,
         startLocation: Location? = nil,
         endLocation: Location? = nil,
         selectedZone: Zone) {
        self.id = id
        self.car = car
        self.date = date
        self.kilometers = kilometers
        self.description = description
        self.participants = participants
        self.isOsloArea = isOsloArea
        self.isUsingRoute = isUsingRoute
        self.startLocation = startLocation
        self.endLocation = endLocation
        self.selectedZone = selectedZone
        self.totalPrice = kilometers * selectedZone.pricePerKm
    }
} 