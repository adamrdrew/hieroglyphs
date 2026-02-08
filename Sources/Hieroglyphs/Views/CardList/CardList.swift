import SwiftUI

/// Middle column view displaying filtered, sorted, searchable card list.
struct CardList: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var isSearchPresented: Bool = false

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        Group {
            if viewModel.selectedProject == nil {
                emptyProjectState
            } else if viewModel.cards.isEmpty {
                emptyCardsState
            } else {
                List(selection: $bindableViewModel.selectedCard) {
                    ForEach(filteredAndSortedCards) { card in
                        CardListEntry(card: card)
                            .tag(card)
                    }
                }
                .listStyle(.plain)
                .searchable(
                    text: $bindableViewModel.searchText,
                    isPresented: $isSearchPresented
                )
            }
        }
        .onChange(of: viewModel.selectedProject) { _, _ in
            viewModel.loadCards()
        }
        .onChange(of: viewModel.focusSearch) { _, newValue in
            if newValue {
                isSearchPresented = true
                viewModel.focusSearch = false
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    viewModel.showNewCardSheet()
                } label: {
                    Label("New Card", systemImage: "plus")
                }
                .disabled(viewModel.selectedProject == nil)
            }
        }
        .sheet(isPresented: $bindableViewModel.showingNewCardSheet) {
            NewCardSheet()
        }
    }

    private var emptyProjectState: some View {
        ContentUnavailableView(
            "No Project Selected",
            systemImage: "folder",
            description: Text("Select a project from the sidebar to view its cards.")
        )
    }

    private var emptyCardsState: some View {
        ContentUnavailableView(
            "No Cards",
            systemImage: "note.text",
            description: Text("Create a card to get started.")
        )
    }

    private var filteredAndSortedCards: [Card] {
        var filtered = viewModel.cards

        // Filter by search text
        if !viewModel.searchText.isEmpty {
            filtered = filtered.filter { card in
                card.title.localizedCaseInsensitiveContains(viewModel.searchText)
            }
        }

        // Filter by status
        if !viewModel.filterStatus.isEmpty {
            filtered = filtered.filter { card in
                viewModel.filterStatus.contains(card.status)
            }
        }

        // Filter by type
        if !viewModel.filterType.isEmpty {
            filtered = filtered.filter { card in
                viewModel.filterType.contains(card.type)
            }
        }

        // Filter by priority
        if !viewModel.filterPriority.isEmpty {
            filtered = filtered.filter { card in
                viewModel.filterPriority.contains(card.priority)
            }
        }

        // Sort by selected criteria
        return sortCards(filtered)
    }

    private func sortCards(_ cards: [Card]) -> [Card] {
        let sorted = cards.sorted { first, second in
            switch viewModel.sortBy {
            case .created:
                return first.created < second.created
            case .updated:
                return first.updated < second.updated
            case .priority:
                return priorityOrder(first.priority) < priorityOrder(second.priority)
            case .status:
                return statusOrder(first.status) < statusOrder(second.status)
            case .title:
                return first.title.localizedCaseInsensitiveCompare(second.title) == .orderedAscending
            }
        }

        return viewModel.sortOrder == .forward ? sorted : sorted.reversed()
    }

    private func priorityOrder(_ priority: Priority) -> Int {
        switch priority {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }

    private func statusOrder(_ status: CardStatus) -> Int {
        switch status {
        case .backlog: return 0
        case .todo: return 1
        case .inProgress: return 2
        case .done: return 3
        case .archived: return 4
        }
    }
}
