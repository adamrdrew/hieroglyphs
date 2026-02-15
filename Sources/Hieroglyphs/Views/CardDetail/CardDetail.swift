import SwiftUI

/// Detail column view for displaying and editing a selected card.
///
/// Combines CardMetadataEditor and CardBodyEditor into a vertical layout.
/// Shows empty state when no card is selected.
struct CardDetail: View {
    @Environment(HieroglyphsVM.self) private var viewModel

    @State private var editableCard: Card?

    var body: some View {
        Group {
            if let editableCard {
                VStack(spacing: 0) {
                    CardMetadataEditor(
                        card: editableCardBinding,
                        onUpdate: saveCard
                    )
                    .frame(height: 300)

                    Divider()

                    CardBodyEditor(
                        content: bodyBinding,
                        onUpdate: { saveCard(debounced: true) }
                    )
                }
                .navigationTitle(editableCard.title)
            } else {
                ContentUnavailableView(
                    "No Card Selected",
                    systemImage: "note.text",
                    description: Text("Select a card from the list to view and edit it.")
                )
            }
        }
        .toolbar {
            if viewModel.selectedProject != nil {
                ToolbarItem(placement: .automatic) {
                    Button {
                        if let card = viewModel.selectedCard {
                            viewModel.createPlanFromCard(card)
                        }
                    } label: {
                        Label("Create Plan", systemImage: "flowchart")
                    }
                    .disabled(viewModel.selectedCard == nil)
                    .help("Create a new plan from this card")
                }
            }
        }
        .onChange(of: viewModel.selectedCard) { _, newCard in
            viewModel.flushPendingCardUpdates()
            editableCard = newCard
        }
        .onAppear {
            editableCard = viewModel.selectedCard
        }
    }

    private var editableCardBinding: Binding<Card> {
        Binding(
            get: { editableCard ?? Card(
                id: UUID(),
                title: "",
                type: .task,
                status: .backlog,
                priority: .medium,
                tags: [],
                created: Date(),
                updated: Date(),
                slug: "",
                body: ""
            ) },
            set: { newValue in
                editableCard = newValue
            }
        )
    }

    private var bodyBinding: Binding<String> {
        Binding(
            get: { editableCard?.body ?? "" },
            set: { newValue in
                guard let card = editableCard else { return }
                editableCard = Card(
                    id: card.id,
                    title: card.title,
                    type: card.type,
                    status: card.status,
                    priority: card.priority,
                    tags: card.tags,
                    created: card.created,
                    updated: Date(),
                    slug: card.slug,
                    body: newValue
                )
            }
        )
    }

    private func saveCard(debounced: Bool = false) {
        guard let editableCard else { return }
        if debounced {
            viewModel.updateCardDebounced(editableCard)
        } else {
            viewModel.updateCard(editableCard)
        }
    }
}
