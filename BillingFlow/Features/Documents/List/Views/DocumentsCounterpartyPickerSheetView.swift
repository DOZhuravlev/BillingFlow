import SwiftUI

struct DocumentsCounterpartyPickerSheetView: View {
    @State private var searchText = ""

    let counterparties: [DocumentsCounterpartyFilterItem]
    let selectedCounterpartyName: String?
    let onSelect: (DocumentsCounterpartyFilterItem?) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    allCounterpartiesRow

                    ForEach(filteredCounterparties) { counterparty in
                        counterpartyRow(counterparty)
                    }
                }
                .padding(20)
            }
            .searchable(text: $searchText, prompt: "Поиск организации")
            .navigationTitle("Контрагенты")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var filteredCounterparties: [DocumentsCounterpartyFilterItem] {
        guard searchText.isEmpty == false else {
            return counterparties
        }

        return counterparties.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var allCounterpartiesRow: some View {
        Button {
            onSelect(nil)
        } label: {
            rowContent(
                title: "Все контрагенты",
                isSelected: selectedCounterpartyName == nil
            )
        }
        .buttonStyle(.plain)
    }

    private func counterpartyRow(_ counterparty: DocumentsCounterpartyFilterItem) -> some View {
        Button {
            onSelect(counterparty)
        } label: {
            rowContent(
                title: counterparty.name,
                isSelected: selectedCounterpartyName == counterparty.name
            )
        }
        .buttonStyle(.plain)
    }

    private func rowContent(
        title: String,
        isSelected: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.black.opacity(0.84))
                .lineLimit(1)

            Spacer()

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(isSelected ? AppColor.Brand.primary : .black.opacity(0.22))
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isSelected ? AppColor.Brand.primary.opacity(0.08) : .black.opacity(0.035))
        }
    }
}
