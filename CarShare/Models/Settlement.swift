import Foundation

struct Settlement: Hashable {
    let payer: User
    let payee: User
    let amount: Double
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(payer)
        hasher.combine(payee)
        hasher.combine(amount)
    }
    
    static func == (lhs: Settlement, rhs: Settlement) -> Bool {
        lhs.payer == rhs.payer && lhs.payee == rhs.payee && lhs.amount == rhs.amount
    }
} 