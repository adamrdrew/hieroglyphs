import SwiftUI

/// Sort UI for sorting cards by various criteria.
struct CardSortPopover: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        VStack(alignment: .leading, spacing: 12) {
            Text("Sort By")
                .font(.headline)

            Picker("Sort By", selection: $bindableViewModel.sortBy) {
                ForEach(CardSortOption.allCases, id: \.self) { option in
                    Text(formatSortLabel(option))
                        .tag(option)
                }
            }
            .pickerStyle(.inline)
            .labelsHidden()

            Divider()

            Picker("Order", selection: $bindableViewModel.sortOrder) {
                Label("Ascending", systemImage: "arrow.up")
                    .tag(SortOrder.forward)
                Label("Descending", systemImage: "arrow.down")
                    .tag(SortOrder.reverse)
            }
            .pickerStyle(.inline)
            .labelsHidden()
        }
        .padding()
        .frame(width: 200)
    }

    private func formatSortLabel(_ option: CardSortOption) -> String {
        switch option {
        case .created:
            return "Date Created"
        case .updated:
            return "Date Updated"
        case .priority:
            return "Priority"
        case .status:
            return "Status"
        case .title:
            return "Title"
        }
    }
}
