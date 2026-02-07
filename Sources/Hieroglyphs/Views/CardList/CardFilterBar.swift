import SwiftUI

/// Filter UI for filtering cards by status, type, and priority.
struct CardFilterBar: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        HStack(spacing: 12) {
            Image(systemName: "line.horizontal.3.decrease.circle")
                .foregroundStyle(.secondary)

            Menu {
                ForEach(CardStatus.allCases, id: \.self) { status in
                    Toggle(
                        formatStatusLabel(status),
                        isOn: Binding(
                            get: { viewModel.filterStatus.contains(status) },
                            set: { isOn in
                                if isOn {
                                    viewModel.filterStatus.insert(status)
                                } else {
                                    viewModel.filterStatus.remove(status)
                                }
                            }
                        )
                    )
                }
            } label: {
                filterLabel(
                    title: "Status",
                    count: viewModel.filterStatus.count
                )
            }

            Menu {
                ForEach(CardType.allCases, id: \.self) { type in
                    Toggle(
                        type.rawValue.capitalized,
                        isOn: Binding(
                            get: { viewModel.filterType.contains(type) },
                            set: { isOn in
                                if isOn {
                                    viewModel.filterType.insert(type)
                                } else {
                                    viewModel.filterType.remove(type)
                                }
                            }
                        )
                    )
                }
            } label: {
                filterLabel(
                    title: "Type",
                    count: viewModel.filterType.count
                )
            }

            Menu {
                ForEach(Priority.allCases, id: \.self) { priority in
                    Toggle(
                        priority.rawValue.capitalized,
                        isOn: Binding(
                            get: { viewModel.filterPriority.contains(priority) },
                            set: { isOn in
                                if isOn {
                                    viewModel.filterPriority.insert(priority)
                                } else {
                                    viewModel.filterPriority.remove(priority)
                                }
                            }
                        )
                    )
                }
            } label: {
                filterLabel(
                    title: "Priority",
                    count: viewModel.filterPriority.count
                )
            }

            if activeFilterCount > 0 {
                Button {
                    clearAllFilters()
                } label: {
                    Text("Clear")
                        .font(.caption)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func filterLabel(title: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Text(title)
            if count > 0 {
                Text("(\(count))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var activeFilterCount: Int {
        viewModel.filterStatus.count +
        viewModel.filterType.count +
        viewModel.filterPriority.count
    }

    private func clearAllFilters() {
        viewModel.filterStatus.removeAll()
        viewModel.filterType.removeAll()
        viewModel.filterPriority.removeAll()
    }

    private func formatStatusLabel(_ status: CardStatus) -> String {
        status.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
