import Foundation

class TripStore: ObservableObject {
    @Published private(set) var trips: [Trip] = []
    
    private let saveKey = "SavedTrips"
    
    init() {
        loadTrips()
    }
    
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        trips.sort { $0.date > $1.date }
        saveTrips()
        objectWillChange.send()
    }
    
    func updateTrip(_ updatedTrip: Trip) {
        if let index = trips.firstIndex(where: { $0.id == updatedTrip.id }) {
            trips[index] = updatedTrip
            trips.sort { $0.date > $1.date }
            saveTrips()
            objectWillChange.send()
        }
    }
    
    private func saveTrips() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(trips)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save trips: \(error.localizedDescription)")
        }
    }
    
    private func loadTrips() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            trips = try decoder.decode([Trip].self, from: data)
            objectWillChange.send()
        } catch {
            print("Failed to load trips: \(error.localizedDescription)")
        }
    }
    
    func deleteTrips(_ tripsToDelete: [Trip]) {
        trips.removeAll { trip in
            tripsToDelete.contains { $0.id == trip.id }
        }
        saveTrips()
        objectWillChange.send()
    }
    
    func deleteTrip(at indexSet: IndexSet) {
        trips.remove(atOffsets: indexSet)
        saveTrips()
        objectWillChange.send()
    }
} 