import Foundation

class LocationStore: ObservableObject {
    @Published private(set) var favoriteLocations: [Location] = []
    private let saveKey = "FavoriteLocations"
    
    init() {
        loadLocations()
    }
    
    func addFavorite(_ location: Location) {
        var newLocation = location
        newLocation.isFavorite = true
        favoriteLocations.append(newLocation)
        saveLocations()
    }
    
    func removeFavorite(_ location: Location) {
        favoriteLocations.removeAll { $0.id == location.id }
        saveLocations()
    }
    
    private func saveLocations() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(favoriteLocations)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save locations: \(error.localizedDescription)")
        }
    }
    
    private func loadLocations() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        do {
            let decoder = JSONDecoder()
            favoriteLocations = try decoder.decode([Location].self, from: data)
        } catch {
            print("Failed to load locations: \(error.localizedDescription)")
        }
    }
} 