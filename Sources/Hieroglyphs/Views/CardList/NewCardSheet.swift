import SwiftUI

/// Modal sheet for creating a new card.
///
/// Design:
/// - Constrained dimensions (500x600) with scrollable content
/// - Semantic typography throughout (headline headers, body content)
/// - Consistent spacing using 8pt scale
/// - Clear visual hierarchy (title primary, pickers secondary, body tertiary)
/// - Body TextEditor constrained within ScrollView for multi-line content
/// - Automatic Liquid Glass treatment on toolbar
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
            ScrollView {
                Form {
                    Section {
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
                    } header: {
                        Text("Card Details")
                            .font(.headline)
                    }

                    Section {
                        TextField("Comma-separated tags", text: $tags)
                    } header: {
                        Text("Tags")
                            .font(.headline)
                    }

                    Section {
                        TextEditor(text: $cardBody)
                            .frame(minHeight: 120, maxHeight: 240)
                            .font(.body)
                    } header: {
                        Text("Body")
                            .font(.headline)
                    }
                }
                .formStyle(.grouped)
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
        .frame(width: 500, height: 600)
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
