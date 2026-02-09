import SwiftUI

/// Detail view for Pharaoh process management and status monitoring.
struct PharaohView: View {
    let project: Project
    @Environment(\.pharaohService) private var pharaohService
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var status: PharaohStatus = .notRunning
    @State private var logs: [String] = []
    @State private var startError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if status.isRunning {
                    runningStateView
                } else {
                    notRunningStateView
                }
            }
            .padding()
        }
        .navigationTitle("Pharaoh")
        .task {
            await monitorStatus()
        }
    }

    @ViewBuilder
    private var notRunningStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pharaoh Server")
                .font(.headline)

            Text("Pharaoh executes Ushabti development phases automatically. Start the server to enable plan dispatch and phase execution.")
                .foregroundStyle(.secondary)

            if let error = startError {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                    Text(error)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }

            Button {
                startPharaoh()
            } label: {
                Label("Start Pharaoh", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    private var runningStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Status")
                    .font(.headline)

                Spacer()

                statusBadge
            }

            if case .busy(let phase) = status {
                phaseInfoRow(label: "Phase", value: phase)
            }

            if case .done(let phase, let cost, let turns) = status {
                phaseInfoRow(label: "Phase", value: phase)
                phaseInfoRow(label: "Cost", value: String(format: "$%.2f", cost))
                phaseInfoRow(label: "Turns", value: "\(turns)")
            }

            if case .blocked(let phase, let error) = status {
                phaseInfoRow(label: "Phase", value: phase)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Error")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(error)
                        .font(.body.monospaced())
                        .foregroundStyle(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }

            Divider()

            logViewerSection

            Divider()

            Button(role: .destructive) {
                stopPharaoh()
            } label: {
                Label("Stop Pharaoh", systemImage: "stop.fill")
            }
            .buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        let (text, color) = statusBadgeProperties

        Text(text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .cornerRadius(6)
    }

    private var statusBadgeProperties: (String, Color) {
        switch status {
        case .notRunning:
            return ("Not Running", .red)
        case .idle:
            return ("Idle", .green)
        case .busy:
            return ("Busy", .orange)
        case .done:
            return ("Done", .blue)
        case .blocked:
            return ("Blocked", .red)
        }
    }

    @ViewBuilder
    private func phaseInfoRow(label: String, value: String) -> some View {
        HStack {
            Text("\(label):")
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.medium)
        }
    }

    @ViewBuilder
    private var logViewerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Logs")
                .font(.headline)

            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(logs, id: \.self) { line in
                        Text(line)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 300)
            .padding()
            .background(Color.secondary.opacity(0.05))
            .cornerRadius(8)
        }
    }

    private func startPharaoh() {
        guard let sourceDirectory = project.sourceDirectory,
              let service = pharaohService else {
            startError = "No source directory configured"
            return
        }

        do {
            try service.start(in: sourceDirectory)
            startError = nil
        } catch {
            startError = error.localizedDescription
        }
    }

    private func stopPharaoh() {
        pharaohService?.stop()
        status = .notRunning
        logs = []
    }

    private func updateStatus() {
        guard let sourceDirectory = project.sourceDirectory,
              let service = pharaohService else {
            status = .notRunning
            return
        }

        status = service.readStatus(from: sourceDirectory)

        if status.isRunning {
            logs = service.readLogs(from: sourceDirectory, count: 50)
        }
    }

    private func monitorStatus() async {
        while !Task.isCancelled {
            updateStatus()
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
