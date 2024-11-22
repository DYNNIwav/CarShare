import Foundation

class TripStore: ObservableObject {
    @Published private(set) var trips: [Trip] = []
    
    private let saveKey = "SavedTrips"
    
    init() {
        loadTrips()
    }
    
    func addTrip(_ trip: Trip) {
        trips.append(trip)
        // Sort trips by date, newest first
        trips.sort { $0.date > $1.date }
        saveTrips()
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
        } catch {
            print("Failed to load trips: \(error.localizedDescription)")
        }
    }
    
    // Updated delete function to handle multiple trips
    func deleteTrips(_ tripsToDelete: [Trip]) {
        trips.removeAll { trip in
            tripsToDelete.contains { $0.id == trip.id }
        }
        saveTrips()
    }
    
    // Keep the original delete function for backward compatibility
    func deleteTrip(at indexSet: IndexSet) {
        trips.remove(atOffsets: indexSet)
        saveTrips()
    }
} 