import SwiftUI

struct DocumentsFilterSheetView: View {
    @Binding var filter: DocumentsFilter
    @Environment(\.dismiss) private var dismiss
    @State private var draftFilter: DocumentsFilter

    init(filter: Binding<DocumentsFilter>) {
        self._filter = filter
        self._draftFilter = State(initialValue: filter.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    typeSection
                    statusSection
                    periodSection
                }
                .padding(20)
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                bottomActions
            }
        }
    }

    private var typeSection: some View {
        filterSection(title: "Тип документа") {
            VStack(spacing: 10) {
                ForEach(DocumentTypeFilter.allCases) { type in
                    optionRow(
                        title: type.title,
                        isSelected: draftFilter.type == type
                    ) {
                        draftFilter.type = type
                    }
                }
            }
        }
    }

    private var statusSection: some View {
        filterSection(title: "Статус") {
            VStack(spacing: 10) {
                ForEach(DocumentStatusFilter.allCases) { status in
                    optionRow(
                        title: status.title,
                        isSelected: draftFilter.status == status
                    ) {
                        draftFilter.status = status
                    }
                }
            }
        }
    }

    private var periodSection: some View {
        filterSection(title: "Период") {
            VStack(spacing: 10) {
                ForEach(DocumentsPeriodFilter.allCases) { period in
                    optionRow(
                        title: period.title,
                        isSelected: draftFilter.period == period
                    ) {
                        draftFilter.period = period
                    }
                }
            }
        }
    }

    private var bottomActions: some View {
        HStack(spacing: 12) {
            Button {
                draftFilter.resetAdvancedFilters()
            } label: {
                Text("Сбросить")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.68))
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.black.opacity(0.06))
                    }
            }
            .buttonStyle(.plain)

            Button {
                filter = draftFilter
                dismiss()
            } label: {
                Text("Показать")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(AppColor.Brand.primary)
                    }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
    }

    private func filterSection<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black.opacity(0.9))

            content()
        }
    }

    private func optionRow(
        title: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.82))

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColor.Brand.primary : .black.opacity(0.22))
            }
            .padding(.horizontal, 16)
            .frame(height: 52)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isSelected ? AppColor.Brand.primary.opacity(0.08) : .black.opacity(0.035))
            }
        }
        .buttonStyle(.plain)
    }
}
