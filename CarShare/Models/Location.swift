import Foundation
import CoreLocation
import MapKit

struct Location: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let coordinate: CLLocationCoordinate2D
    var isFavorite: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, isFavorite
        case latitude
        case longitude
    }
    
    init(id: UUID = UUID(), name: String, coordinate: CLLocationCoordinate2D, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.isFavorite = isFavorite
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
    }
    
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.id == rhs.id
    }
} 