import Foundation

protocol TopOrganizationsServiceProtocol {
    func makeTopOrganizations(
        documents: [BusinessDocument],
        limit: Int
    ) -> [TopOrganizationMetric]
}

struct TopOrganizationsService: TopOrganizationsServiceProtocol {

    func makeTopOrganizations(
        documents: [BusinessDocument],
        limit: Int = 3
    ) -> [TopOrganizationMetric] {

        // TODO: Replace mock data with aggregation from documents.

        return [
            TopOrganizationMetric(
                id: "alfa",
                name: "ООО Альфа",
                documentCount: 8,
                totalAmount: "185 000 ₽"
            ),

            TopOrganizationMetric(
                id: "beta",
                name: "ИП Петров П.П.",
                documentCount: 5,
                totalAmount: "92 500 ₽"
            ),

            TopOrganizationMetric(
                id: "gamma",
                name: "ООО Вектор",
                documentCount: 3,
                totalAmount: "74 000 ₽"
            )
        ]
        .prefix(limit)
        .map { $0 }
    }

}
