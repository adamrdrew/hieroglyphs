import SwiftUI

/// Modal sheet for adding a card to a plan.
struct AddCardToPlanSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    let plan: Plan

    @State private var selectedCard: Card?

    var body: some View {
        NavigationStack {
            List(availableCards, id: \.id, selection: $selectedCard) { card in
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
            .navigationTitle("Add Card to Plan")
            .toolbar {
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

    private func addCard() {
        guard let selectedCard else { return }
        viewModel.addCardToPlan(
            cardSlug: selectedCard.slug,
            planSlug: plan.slug
        )
        dismiss()
    }
}
