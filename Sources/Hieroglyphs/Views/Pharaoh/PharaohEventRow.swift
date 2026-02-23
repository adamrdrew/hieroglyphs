import SwiftUI

/// Displays a single event from the Pharaoh event stream.
struct PharaohEventRow: View {
    let event: PharaohEvent

    var body: some View {
        if event.type == .turn {
            turnSeparator
        } else {
            eventRow
        }
    }

    @ViewBuilder
    private var eventRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(event.timestamp, format: .dateTime.hour().minute().second())
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.tertiary)
                    .frame(width: 60, alignment: .trailing)

                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                    .frame(width: 16)

                Text(event.summary)
                    .font(summaryFont)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .padding(.vertical, 2)

            if event.hasDetail {
                PharaohEventDetailView(event: event)
            }
        }
    }

    @ViewBuilder
    private var turnSeparator: some View {
        VStack(spacing: 4) {
            Divider()
            Text(event.summary)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch event.type {
        case .toolCall:
            return "wrench.fill"
        case .toolProgress:
            return "clock.arrow.circlepath"
        case .toolSummary:
            return "checkmark.circle"
        case .text:
            return "text.bubble"
        case .turn:
            return ""
        case .status:
            return "info.circle"
        case .result:
            return "checkmark.seal.fill"
        case .error:
            return "exclamationmark.triangle.fill"
        }
    }

    private var iconColor: Color {
        switch event.type {
        case .toolCall:
            return .accentColor
        case .toolProgress:
            return .secondary
        case .toolSummary:
            return .green
        case .text:
            return .secondary
        case .turn:
            return .secondary
        case .status:
            return .blue
        case .result:
            return .green
        case .error:
            return .red
        }
    }

    private var summaryFont: Font {
        switch event.type {
        case .toolCall:
            return .callout.monospaced()
        case .toolProgress:
            return .callout
        case .toolSummary:
            return .callout
        case .text:
            return .callout
        case .turn:
            return .callout
        case .status:
            return .callout
        case .result:
            return .callout.bold()
        case .error:
            return .callout.bold()
        }
    }
}
