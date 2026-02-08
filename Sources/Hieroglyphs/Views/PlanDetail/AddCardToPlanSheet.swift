import SwiftUI

/// Modal sheet for adding a card to a plan.
struct AddCardToPlanSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let plan: Plan

    @State private var selectedCard: Card?
    @State private var searchText = ""
    @State private var filterStatus: Set<CardStatus> = []
    @State private var filterType: Set<CardType> = []
    @State private var filterPriority: Set<Priority> = []

    var body: some View {
        NavigationStack {
            List(filteredCards, id: \.id, selection: $selectedCard) { card in
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.title)
                        .font(.body)

                    HStack(spacing: 8) {
                        Text(card.type.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(card.status.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(card.priority.rawValue)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .tag(card)
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Search cards")
            .navigationTitle("Add Card to Plan")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(CardStatus.allCases, id: \.self) { status in
                            Toggle(
                                formatStatusLabel(status),
                                isOn: Binding(
                                    get: { filterStatus.contains(status) },
                                    set: { isOn in
                                        if isOn {
                                            filterStatus.insert(status)
                                        } else {
                                            filterStatus.remove(status)
                                        }
                                    }
                                )
                            )
                        }
                    } label: {
                        Label("Status", systemImage: "line.horizontal.3.decrease.circle")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(CardType.allCases, id: \.self) { type in
                            Toggle(
                                type.rawValue.capitalized,
                                isOn: Binding(
                                    get: { filterType.contains(type) },
                                    set: { isOn in
                                        if isOn {
                                            filterType.insert(type)
                                        } else {
                                            filterType.remove(type)
                                        }
                                    }
                                )
                            )
                        }
                    } label: {
                        Label("Type", systemImage: "line.horizontal.3.decrease.circle")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Menu {
                        ForEach(Priority.allCases, id: \.self) { priority in
                            Toggle(
                                priority.rawValue.capitalized,
                                isOn: Binding(
                                    get: { filterPriority.contains(priority) },
                                    set: { isOn in
                                        if isOn {
                                            filterPriority.insert(priority)
                                        } else {
                                            filterPriority.remove(priority)
                                        }
                                    }
                                )
                            )
                        }
                    } label: {
                        Label("Priority", systemImage: "line.horizontal.3.decrease.circle")
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addCard()
                    }
                    .disabled(selectedCard == nil)
                }
            }
        }
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            viewModel.loadCards()
        }
    }

    private var availableCards: [Card] {
        viewModel.cards.filter { card in
            !plan.linkedCardSlugs.contains(card.slug)
        }
    }

    private var filteredCards: [Card] {
        var filtered = availableCards

        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { card in
                card.title.localizedCaseInsensitiveContains(searchText)
            }
        }

        // Filter by status
        if !filterStatus.isEmpty {
            filtered = filtered.filter { card in
                filterStatus.contains(card.status)
            }
        }

        // Filter by type
        if !filterType.isEmpty {
            filtered = filtered.filter { card in
                filterType.contains(card.type)
            }
        }

        // Filter by priority
        if !filterPriority.isEmpty {
            filtered = filtered.filter { card in
                filterPriority.contains(card.priority)
            }
        }

        return filtered
    }

    private func addCard() {
        guard let selectedCard else { return }
        viewModel.addCardToPlan(
            cardSlug: selectedCard.slug,
            planSlug: plan.slug
        )
        dismiss()
    }

    private func formatStatusLabel(_ status: CardStatus) -> String {
        status.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
