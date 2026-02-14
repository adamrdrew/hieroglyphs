import SwiftUI

/// Modal sheet for adding a card to a plan.
struct AddCardToPlanSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let plan: Plan

    @State private var selectedCards: Set<Card.ID> = []
    @State private var searchText = ""
    @State private var filterStatus: Set<CardStatus> = []
    @State private var filterType: Set<CardType> = []
    @State private var filterPriority: Set<Priority> = []

    var body: some View {
        NavigationStack {
            List(filteredCards, id: \.id, selection: $selectedCards) { card in
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
                    Button(addButtonLabel) {
                        addCard()
                    }
                    .disabled(selectedCards.isEmpty)
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

    private var addButtonLabel: String {
        let count = selectedCards.count
        if count == 0 {
            return "Add"
        } else if count == 1 {
            return "Add Card"
        } else {
            return "Add \(count) Cards"
        }
    }

    private func addCard() {
        guard !selectedCards.isEmpty else { return }
        let selectedCardObjects = filteredCards.filter { selectedCards.contains($0.id) }
        let cardSlugs = selectedCardObjects.map(\.slug)
        viewModel.addCardsToPlan(cardSlugs: cardSlugs, planSlug: plan.slug)
        dismiss()
    }

    private func formatStatusLabel(_ status: CardStatus) -> String {
        status.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
