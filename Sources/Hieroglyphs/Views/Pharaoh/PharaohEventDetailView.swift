import SwiftUI

/// Displays inline detail information for a Pharaoh event.
struct PharaohEventDetailView: View {
    let event: PharaohEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            switch event.type {
            case .toolCall:
                toolCallDetail
            case .turn:
                turnDetail
            case .text:
                textDetail
            case .result:
                resultDetail
            default:
                EmptyView()
            }
        }
        .font(.caption2)
        .foregroundStyle(.tertiary)
        .padding(.leading, 76)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var toolCallDetail: some View {
        if let toolName = event.toolName {
            detailRow(label: "Tool", value: toolName)
        }
        if let toolInput = event.toolInput {
            detailRow(label: "Input", value: toolInput)
        }
    }

    @ViewBuilder
    private var turnDetail: some View {
        if let turnNumber = event.turnNumber {
            detailRow(label: "Turn", value: "\(turnNumber)")
        }
        if let inputTokens = event.inputTokens {
            detailRow(label: "Input Tokens", value: "\(inputTokens)")
        }
        if let outputTokens = event.outputTokens {
            detailRow(label: "Output Tokens", value: "\(outputTokens)")
        }
    }

    @ViewBuilder
    private var textDetail: some View {
        if let fullText = event.fullText {
            detailRow(label: "Full Text", value: fullText)
        }
    }

    @ViewBuilder
    private var resultDetail: some View {
        if let resultTurns = event.resultTurns {
            detailRow(label: "Total Turns", value: "\(resultTurns)")
        }
        if let resultCostUsd = event.resultCostUsd {
            detailRow(
                label: "Total Cost",
                value: String(format: "$%.4f", resultCostUsd)
            )
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label + ":")
                .foregroundStyle(.tertiary)
            Text(value)
                .lineLimit(nil)
        }
    }
}
