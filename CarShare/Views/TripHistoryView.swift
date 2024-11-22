import SwiftUI

struct TripHistoryView: View {
    @EnvironmentObject private var tripStore: TripStore
    @State private var selectedUser: User?
    
    var filteredTrips: [Trip] {
        guard let user = selectedUser else {
            return tripStore.trips
        }
        return tripStore.trips.filter { trip in
            trip.participants.contains(user)
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // User Filter Picker
                Picker("Filter by User", selection: $selectedUser) {
                    Text("All Trips")
                        .tag(nil as User?)
                    ForEach(User.users) { user in
                        Text(user.name)
                            .tag(Optional(user))
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                List {
                    if tripStore.trips.isEmpty {
                        Text("No trips registered yet")
                            .foregroundColor(.secondary)
                    } else if filteredTrips.isEmpty && selectedUser != nil {
                        Text("No trips found for \(selectedUser?.name ?? "")")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredTrips) { trip in
                            NavigationLink(destination: EditTripView(trip: trip)) {
                                if selectedUser == nil {
                                    AllTripsRow(trip: trip)
                                } else {
                                    UserTripRow(trip: trip, user: selectedUser!)
                                }
                            }
                        }
                        .onDelete(perform: { indexSet in
                            let tripsToDelete = indexSet.map { filteredTrips[$0] }
                            tripStore.deleteTrips(tripsToDelete)
                        })
                    }
                }
            }
            .navigationTitle("Trip History")
        }
    }
}

// Row for showing all trips (no user filter)
struct AllTripsRow: View {
    let trip: Trip
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.car.name)
                .font(.headline)
            Text(trip.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Participants: \(trip.participants.map { $0.name }.joined(separator: ", "))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text(trip.date, style: .date)
                Spacer()
                Text("\(String(format: "%.1f km", trip.kilometers))")
            }
            .font(.caption)
            
            HStack {
                Spacer()
                Text(String(format: "Total: %.2f kr", trip.totalPrice))
                    .font(.subheadline)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// Row for showing user-specific trips
struct UserTripRow: View {
    let trip: Trip
    let user: User
    
    private var costPerParticipant: Double {
        trip.totalPrice / Double(trip.participants.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.car.name)
                .font(.headline)
            Text(trip.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text(trip.date, style: .date)
                Spacer()
                Text("\(String(format: "%.1f km", trip.kilometers))")
            }
            .font(.caption)
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("Total trip: \(String(format: "%.2f kr", trip.totalPrice))")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("Your share: \(String(format: "%.2f kr", costPerParticipant))")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                Text("Split with \(trip.participants.count - 1) other\(trip.participants.count > 2 ? "s" : "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TripHistoryView()
        .environmentObject(TripStore())
} 