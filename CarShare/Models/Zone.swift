import Foundation

struct Zone: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let range: ClosedRange<Double>
    let pricePerKm: Double
    let isOsloArea: Bool
    
    init(id: UUID = UUID(), name: String, range: ClosedRange<Double>, pricePerKm: Double, isOsloArea: Bool) {
        self.id = id
        self.name = name
        self.range = range
        self.pricePerKm = pricePerKm
        self.isOsloArea = isOsloArea
    }
    
    static let zones = [
        Zone(name: "0-50km (Oslo + Bærum)", range: 0...50, pricePerKm: 4.5, isOsloArea: true),
        Zone(name: "0-50km (andre steder)", range: 0...50, pricePerKm: 3.0, isOsloArea: false),
        Zone(name: "50-250km", range: 50...250, pricePerKm: 2.5, isOsloArea: false),
        Zone(name: "250-500km", range: 250...500, pricePerKm: 2.2, isOsloArea: false),
        Zone(name: "500km+", range: 500...Double.infinity, pricePerKm: 1.8, isOsloArea: false)
    ]
    
    static func calculatePrice(kilometers: Double, isOsloArea: Bool) -> Double {
        let applicableZone = zones.first { zone in
            zone.range.contains(kilometers) && (zone.range.upperBound <= 50 ? zone.isOsloArea == isOsloArea : true)
        } ?? zones.last!
        
        return kilometers * applicableZone.pricePerKm
    }
    
    var priceDescription: String {
        return String(format: "%.1f kr/km", pricePerKm)
    }
    
    // Add Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Zone, rhs: Zone) -> Bool {
        lhs.id == rhs.id
    }
    
    // Add custom Codable implementation for ClosedRange
    enum CodingKeys: String, CodingKey {
        case id, name, pricePerKm, isOsloArea
        case rangeLower = "rangeLowerBound"
        case rangeUpper = "rangeUpperBound"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        pricePerKm = try container.decode(Double.self, forKey: .pricePerKm)
        isOsloArea = try container.decode(Bool.self, forKey: .isOsloArea)
        
        let lower = try container.decode(Double.self, forKey: .rangeLower)
        let upper = try container.decode(Double.self, forKey: .rangeUpper)
        range = lower...upper
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(pricePerKm, forKey: .pricePerKm)
        try container.encode(isOsloArea, forKey: .isOsloArea)
        try container.encode(range.lowerBound, forKey: .rangeLower)
        try container.encode(range.upperBound, forKey: .rangeUpper)
    }
} 