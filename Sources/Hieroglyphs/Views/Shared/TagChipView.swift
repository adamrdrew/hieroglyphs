import SwiftUI

/// Displays a single tag as a chip with a delete button.
///
/// Visual style: rounded rectangle background with secondary color and small font.
/// Delete button uses SF Symbol xmark.circle.fill.
struct TagChipView: View {
    let tag: String
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)

            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.secondary.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
