import SwiftUI

/// Edits card frontmatter metadata fields.
///
/// Displays editable fields for title, type, status, priority, and tags.
/// All changes trigger the onUpdate callback to save to disk.
struct CardMetadataEditor: View {
    @Binding var card: Card
    let onUpdate: () -> Void

    @State private var newTag = ""

    var body: some View {
        Form {
            Section {
                TextField("Title", text: titleBinding)
                    .textFieldStyle(.plain)
            }

            Section("Details") {
                Picker("Type", selection: typeBinding) {
                    ForEach(CardType.allCases, id: \.self) { type in
                        Text(formatLabel(type.rawValue)).tag(type)
                    }
                }
                .pickerStyle(.menu)

                Picker("Status", selection: statusBinding) {
                    ForEach(CardStatus.allCases, id: \.self) { status in
                        Text(formatLabel(status.rawValue)).tag(status)
                    }
                }
                .pickerStyle(.menu)

                Picker("Priority", selection: priorityBinding) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(formatLabel(priority.rawValue)).tag(priority)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Tags") {
                if !card.tags.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(card.tags, id: \.self) { tag in
                            TagChipView(tag: tag) {
                                removeTag(tag)
                            }
                        }
                    }
                }

                HStack {
                    TextField("Add tag", text: $newTag)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            addTag()
                        }

                    Button {
                        addTag()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .formStyle(.grouped)
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { card.title },
            set: { newValue in
                card = Card(
                    id: card.id,
                    title: newValue,
                    type: card.type,
                    status: card.status,
                    priority: card.priority,
                    tags: card.tags,
                    created: card.created,
                    updated: Date(),
                    slug: card.slug,
                    body: card.body
                )
                onUpdate()
            }
        )
    }

    private var typeBinding: Binding<CardType> {
        Binding(
            get: { card.type },
            set: { newValue in
                card = Card(
                    id: card.id,
                    title: card.title,
                    type: newValue,
                    status: card.status,
                    priority: card.priority,
                    tags: card.tags,
                    created: card.created,
                    updated: Date(),
                    slug: card.slug,
                    body: card.body
                )
                onUpdate()
            }
        )
    }

    private var statusBinding: Binding<CardStatus> {
        Binding(
            get: { card.status },
            set: { newValue in
                card = Card(
                    id: card.id,
                    title: card.title,
                    type: card.type,
                    status: newValue,
                    priority: card.priority,
                    tags: card.tags,
                    created: card.created,
                    updated: Date(),
                    slug: card.slug,
                    body: card.body
                )
                onUpdate()
            }
        )
    }

    private var priorityBinding: Binding<Priority> {
        Binding(
            get: { card.priority },
            set: { newValue in
                card = Card(
                    id: card.id,
                    title: card.title,
                    type: card.type,
                    status: card.status,
                    priority: newValue,
                    tags: card.tags,
                    created: card.created,
                    updated: Date(),
                    slug: card.slug,
                    body: card.body
                )
                onUpdate()
            }
        )
    }

    private func formatLabel(_ rawValue: String) -> String {
        rawValue.replacingOccurrences(of: "-", with: " ").capitalized
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !card.tags.contains(trimmed) else {
            newTag = ""
            return
        }

        card = Card(
            id: card.id,
            title: card.title,
            type: card.type,
            status: card.status,
            priority: card.priority,
            tags: card.tags + [trimmed],
            created: card.created,
            updated: Date(),
            slug: card.slug,
            body: card.body
        )
        newTag = ""
        onUpdate()
    }

    private func removeTag(_ tag: String) {
        card = Card(
            id: card.id,
            title: card.title,
            type: card.type,
            status: card.status,
            priority: card.priority,
            tags: card.tags.filter { $0 != tag },
            created: card.created,
            updated: Date(),
            slug: card.slug,
            body: card.body
        )
        onUpdate()
    }
}

/// Simple flow layout for tag chips.
///
/// Wraps content horizontally and creates new rows as needed.
private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let result = arrangeViews(
            proposal: proposal,
            subviews: subviews
        )
        return result.size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        let result = arrangeViews(
            proposal: proposal,
            subviews: subviews
        )

        for (index, subview) in subviews.enumerated() {
            let position = result.positions[index]
            subview.place(
                at: CGPoint(
                    x: bounds.minX + position.x,
                    y: bounds.minY + position.y
                ),
                proposal: .unspecified
            )
        }
    }

    private func arrangeViews(
        proposal: ProposedViewSize,
        subviews: Subviews
    ) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0

        let proposedWidth = proposal.width ?? .infinity

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > proposedWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }

        let totalHeight = currentY + lineHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
