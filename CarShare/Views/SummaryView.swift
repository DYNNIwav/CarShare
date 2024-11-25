import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var tripStore: TripStore
    @State private var expandedUsers: Set<UUID> = []
    
    // Calculate total trip costs for each user based on their participation
    var totalTripCosts: [User: Double] {
        var costs = [User: Double]()
        
        for trip in tripStore.trips {
            let costPerParticipant = trip.totalPrice / Double(trip.participants.count)
            for participant in trip.participants {
                costs[participant, default: 0] += costPerParticipant
            }
        }
        
        return costs
    }
    
    // Get trips for a specific user
    func userTrips(_ user: User) -> [Trip] {
        tripStore.trips.filter { $0.participants.contains(user) }
    }
    
    // Get sorted trips for a user
    func sortedTrips(for user: User) -> [Trip] {
        userTrips(user).sorted { $0.date > $1.date }
    }
    
    // Calculate user's share for a specific trip
    func userShare(for trip: Trip) -> Double {
        trip.totalPrice / Double(trip.participants.count)
    }
    
    // Calculate settlements based on trip participation
    var settlements: [Settlement] {
        var settlements = [Settlement]()
        var balances = [User: Double]()
        
        // Initialize balances to 0 for all users
        for user in User.users {
            balances[user] = 0
        }
        
        // For each trip, participants owe their share to non-participants
        for trip in tripStore.trips {
            let nonParticipants = Set(User.users).subtracting(trip.participants)
            
            if !nonParticipants.isEmpty {
                // Each participant owes their share of the full trip cost to non-participants
                let amountPerParticipant = trip.totalPrice / Double(trip.participants.count)
                
                // Update balances
                for participant in trip.participants {
                    balances[participant, default: 0] -= amountPerParticipant // They owe money
                }
                
                for nonParticipant in nonParticipants {
                    balances[nonParticipant, default: 0] += trip.totalPrice / Double(nonParticipants.count) // They receive money
                }
            }
        }
        
        // Create settlements based on final balances
        let debtors = User.users.filter { balances[$0, default: 0] < -0.01 }  // These need to pay
        let creditors = User.users.filter { balances[$0, default: 0] > 0.01 }  // These should receive
        
        var remainingBalances = balances
        
        // Match largest debts with largest credits
        for debtor in debtors {
            for creditor in creditors {
                let debtAmount = -remainingBalances[debtor, default: 0]  // How much they need to pay
                let creditAmount = remainingBalances[creditor, default: 0]  // How much they should receive
                
                if debtAmount > 0.01 && creditAmount > 0.01 {
                    let transferAmount = min(debtAmount, creditAmount)
                    
                    settlements.append(Settlement(
                        payer: debtor,
                        payee: creditor,
                        amount: transferAmount
                    ))
                    
                    // Update remaining balances
                    remainingBalances[debtor, default: 0] += transferAmount
                    remainingBalances[creditor, default: 0] -= transferAmount
                }
            }
        }
        
        return settlements.sorted { $0.amount > $1.amount }
    }
    
    // View for a single user's trip details
    private func UserTripDetails(user: User) -> some View {
        let trips = sortedTrips(for: user)
        return ForEach(Array(trips.enumerated()), id: \.element.id) { index, trip in
            HStack {
                VStack(alignment: .leading) {
                    Text(trip.description)
                        .font(.subheadline)
                    Text(trip.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.leading)
                
                Spacer()
                
                Text(String(format: "%.2f kr", userShare(for: trip)))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
            
            if index < trips.count - 1 {
                Divider()
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Total Trip Costs Per User")) {
                    ForEach(User.users) { user in
                        VStack(spacing: 0) {
                            HStack {
                                Text(user.name)
                                Spacer()
                                VStack(alignment: .trailing) {
                                    Text(String(format: "%.2f kr", totalTripCosts[user, default: 0]))
                                        .foregroundColor(.primary)
                                    if totalTripCosts[user, default: 0] > 0 {
                                        Text("Total share of trips")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("No trips")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                if !userTrips(user).isEmpty {
                                    Image(systemName: expandedUsers.contains(user.id) ? "chevron.up" : "chevron.down")
                                        .foregroundColor(.blue)
                                        .padding(.leading)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                withAnimation {
                                    if expandedUsers.contains(user.id) {
                                        expandedUsers.remove(user.id)
                                    } else {
                                        expandedUsers.insert(user.id)
                                    }
                                }
                            }
                            
                            if expandedUsers.contains(user.id) {
                                Divider()
                                    .padding(.vertical, 8)
                                UserTripDetails(user: user)
                            }
                        }
                    }
                }
                
                Section(header: Text("Required Settlements")) {
                    if settlements.isEmpty {
                        Text("No settlements needed")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(settlements, id: \.self) { settlement in
                            HStack {
                                Text("\(settlement.payer.name) → \(settlement.payee.name)")
                                Spacer()
                                Text(String(format: "%.2f kr", settlement.amount))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Summary")
        }
    }
}

#Preview {
    SummaryView()
        .environmentObject(TripStore())
} 