import SwiftUI

/// Modal sheet for creating a new card.
struct NewCardSheet: View {
    @Environment(HieroglyphsVM.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var cardBody = ""
    @State private var tags = ""
    @State private var type: CardType = .task
    @State private var status: CardStatus = .todo
    @State private var priority: Priority = .medium

    var body: some View {
        NavigationStack {
            Form {
                Section("Card Details") {
                    TextField("Title", text: $title)

                    Picker("Type", selection: $type) {
                        ForEach(CardType.allCases, id: \.self) { cardType in
                            Text(cardType.rawValue.capitalized)
                                .tag(cardType)
                        }
                    }

                    Picker("Status", selection: $status) {
                        ForEach(CardStatus.allCases, id: \.self) { cardStatus in
                            Text(formatStatusLabel(cardStatus))
                                .tag(cardStatus)
                        }
                    }

                    Picker("Priority", selection: $priority) {
                        ForEach(Priority.allCases, id: \.self) { cardPriority in
                            Text(cardPriority.rawValue.capitalized)
                                .tag(cardPriority)
                        }
                    }
                }

                Section("Tags") {
                    TextField("Comma-separated tags", text: $tags)
                }

                Section("Body") {
                    ScrollView {
                        TextEditor(text: $cardBody)
                            .frame(minHeight: 100, maxHeight: 300)
                            .font(.body)
                    }
                }
            }
            .navigationTitle("New Card")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveCard()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
        .frame(minWidth: 500, minHeight: 500)
    }

    private func saveCard() {
        let parsedTags = tags
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        viewModel.createCard(
            title: title,
            type: type,
            status: status,
            priority: priority,
            tags: parsedTags,
            body: cardBody
        )

        dismiss()
    }

    private func formatStatusLabel(_ status: CardStatus) -> String {
        status.rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }
}
