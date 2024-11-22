import Foundation

struct Zone: Identifiable, Hashable {
    let id: UUID = UUID()
    let name: String
    let range: ClosedRange<Double>
    let pricePerKm: Double
    let isOsloArea: Bool
    
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
} 