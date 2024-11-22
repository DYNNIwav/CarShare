import SwiftUI

struct SummaryView: View {
    @EnvironmentObject private var tripStore: TripStore
    
    // Calculate total trip costs for each user based on their participation
    var totalTripCosts: [User: Double] {
        var costs = [User: Double]()
        
        for trip in tripStore.trips {
            // For each trip, split the cost only among participants
            let costPerParticipant = trip.totalPrice / Double(trip.participants.count)
            for participant in trip.participants {
                costs[participant, default: 0] += costPerParticipant
            }
        }
        
        return costs
    }
    
    // Calculate settlements based on trip participation
    var settlements: [Settlement] {
        var settlements = [Settlement]()
        var balances = [User: Double]()
        
        // Calculate total balance for each user
        for user in User.users {
            let totalOwed = tripStore.trips.reduce(0.0) { total, trip in
                if trip.participants.contains(user) {
                    // This user participated, so they owe their share to non-participants
                    let nonParticipants = Set(User.users).subtracting(trip.participants)
                    let amountPerNonParticipant = trip.totalPrice / Double(trip.participants.count) / Double(nonParticipants.count)
                    return total - (amountPerNonParticipant * Double(nonParticipants.count))
                } else {
                    // This user didn't participate, so they should receive from participants
                    let participantCount = trip.participants.count
                    let amountPerNonParticipant = trip.totalPrice / Double(User.users.count - participantCount)
                    return total + amountPerNonParticipant
                }
            }
            balances[user] = totalOwed
        }
        
        // Sort users by their balance (negative means they owe money)
        let sortedUsers = User.users.sorted { balances[$0, default: 0] < balances[$1, default: 0] }
        
        var debtors = sortedUsers.filter { balances[$0, default: 0] < -0.01 }  // Users who owe money
        var creditors = sortedUsers.filter { balances[$0, default: 0] > 0.01 }  // Users who should receive money
        
        // Create settlements by matching largest debts with largest credits
        while !debtors.isEmpty && !creditors.isEmpty {
            let debtor = debtors[0]
            let creditor = creditors[0]
            
            let debtAmount = -balances[debtor, default: 0]
            let creditAmount = balances[creditor, default: 0]
            
            let settlementAmount = min(debtAmount, creditAmount)
            
            if settlementAmount > 0.01 {
                settlements.append(Settlement(
                    payer: debtor,
                    payee: creditor,
                    amount: settlementAmount
                ))
            }
            
            // Update balances
            balances[debtor, default: 0] += settlementAmount
            balances[creditor, default: 0] -= settlementAmount
            
            // Remove users who have settled their balances
            if abs(balances[debtor, default: 0]) < 0.01 {
                debtors.removeFirst()
            }
            if abs(balances[creditor, default: 0]) < 0.01 {
                creditors.removeFirst()
            }
        }
        
        return settlements
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Trip Costs Overview")) {
                    ForEach(User.users) { user in
                        HStack {
                            Text(user.name)
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(String(format: "%.2f kr", totalTripCosts[user, default: 0]))
                                    .foregroundColor(.primary)
                                if totalTripCosts[user, default: 0] > 0 {
                                    Text("Owes for car usage")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                } else {
                                    Text("Should be compensated")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
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