import Foundation

struct TopOrganizationMetric: Identifiable {
    let id: String
    let name: String
    let documentCount: Int
    let totalAmount: String
    let party: DocumentParty
    let documents: [BusinessDocument]
}
