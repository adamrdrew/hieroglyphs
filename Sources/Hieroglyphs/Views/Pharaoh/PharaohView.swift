import SwiftUI

/// Detail view for Pharaoh process management and status monitoring.
struct PharaohView: View {
    let project: Project
    @Environment(\.pharaohService) private var pharaohService
    @Environment(HieroglyphsVM.self) private var viewModel
    @State private var status: PharaohStatus = .notRunning
    @State private var previousStatus: PharaohStatus = .notRunning
    @State private var serverInfo: PharaohServerInfo?
    @State private var startErrorMessage = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isStarting = false
    @State private var showStartErrorAlert = false

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
        .alert("Phase Failed", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Failed to Start Pharaoh", isPresented: $showStartErrorAlert) {
            Button("OK") { }
        } message: {
            Text(startErrorMessage)
        }
    }

    @ViewBuilder
    private var notRunningStateView: some View {
        if isStarting {
            VStack(spacing: 12) {
                ProgressView()
                Text("Starting Pharaoh…")
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("Pharaoh Server")
                    .font(.headline)

                Text("Pharaoh executes Ushabti development phases automatically. Start the server to enable plan dispatch and phase execution.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    @Bindable var bindableViewModel = viewModel
                    Picker("Model", selection: $bindableViewModel.pharaohModel) {
                        Text("Opus").tag("opus")
                        Text("Sonnet").tag("sonnet")
                        Text("Haiku").tag("haiku")
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Button {
                    startPharaoh()
                } label: {
                    Label("Start Pharaoh", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    @ViewBuilder
    private var runningStateView: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let serverInfo = serverInfo {
                serverInfoSection(serverInfo)
                Divider()
            }

            HStack {
                Text("Status")
                    .font(.headline)

                Spacer()

                statusBadge
            }

            if case .busy(let phase, let turnsElapsed, let runningCostUsd, let phaseStarted) = status {
                phaseInfoRow(label: "Phase", value: phase)
                phaseInfoRow(label: "Turns", value: "\(turnsElapsed)")
                phaseInfoRow(label: "Running Cost", value: String(format: "$%.4f", runningCostUsd))

                if let phaseStarted = phaseStarted {
                    HStack {
                        Text("Elapsed:")
                            .foregroundStyle(.secondary)
                        Text(phaseStarted, style: .relative)
                            .fontWeight(.medium)
                    }
                }
            }

            if case .done(let phase, let costUsd, let turns) = status {
                phaseInfoRow(label: "Phase", value: phase)
                phaseInfoRow(label: "Cost", value: String(format: "$%.4f", costUsd))
                phaseInfoRow(label: "Turns", value: "\(turns)")
            }

            if case .blocked(let phase, let error, let costUsd, let turns) = status {
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

                phaseInfoRow(label: "Cost", value: String(format: "$%.4f", costUsd))
                phaseInfoRow(label: "Turns", value: "\(turns)")
            }

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
    private func serverInfoSection(_ info: PharaohServerInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Server Information")
                .font(.headline)

            phaseInfoRow(
                label: "Pharaoh Version",
                value: info.pharaohVersion
            )
            phaseInfoRow(
                label: "Ushabti Version",
                value: info.ushabtiVersion
            )
            phaseInfoRow(
                label: "Model",
                value: info.model
            )
            phaseInfoRow(
                label: "Working Directory",
                value: truncatePath(info.cwd)
            )
            phaseInfoRow(
                label: "PID",
                value: "\(info.pid)"
            )
            phaseInfoRow(
                label: "Started",
                value: relativeDateString(info.started)
            )
            phaseInfoRow(
                label: "Phases Completed",
                value: "\(info.phasesCompleted)"
            )
        }
    }

    private func truncatePath(_ path: String) -> String {
        if path.count > 50 {
            let components = path.split(separator: "/")
            if components.count > 3 {
                let last = components.suffix(2).joined(separator: "/")
                return ".../" + last
            }
        }
        return path
    }

    private func relativeDateString(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func startPharaoh() {
        isStarting = true

        guard let sourceDirectory = project.sourceDirectory,
              let service = pharaohService else {
            startErrorMessage = "No source directory configured"
            isStarting = false
            showStartErrorAlert = true
            return
        }

        do {
            try service.start(in: sourceDirectory, model: viewModel.pharaohModel)
        } catch {
            startErrorMessage = error.localizedDescription
            isStarting = false
            showStartErrorAlert = true
        }
    }

    private func stopPharaoh() {
        pharaohService?.stop()
        status = .notRunning
    }

    private func updateStatus() {
        guard let sourceDirectory = project.sourceDirectory,
              let service = pharaohService else {
            status = .notRunning
            serverInfo = nil
            return
        }

        let newStatus = service.readStatus(from: sourceDirectory)
        let newServerInfo = service.readServerInfo(from: sourceDirectory)

        if newServerInfo != serverInfo {
            serverInfo = newServerInfo
        }

        if case .busy = previousStatus, case .done(let phase, _, _) = newStatus {
            autoCompletePlan(phase: phase)
        }

        if case .busy = previousStatus, case .blocked(_, let error, _, _) = newStatus {
            errorMessage = error
            showErrorAlert = true
        }

        previousStatus = status
        if newStatus != status {
            status = newStatus
        }

        if newStatus != .notRunning && isStarting {
            isStarting = false
        }
    }

    private func autoCompletePlan(phase: String) {
        guard let matchingPlan = viewModel.plans.first(where: {
            $0.slug == phase && $0.status == .inProgress
        }) else {
            return
        }

        viewModel.updatePlanStatus(plan: matchingPlan, status: .done)
        print("[Hieroglyphs] Auto-completed plan: \(phase)")
    }

    private func monitorStatus() async {
        while !Task.isCancelled {
            updateStatus()
            try? await Task.sleep(for: .seconds(2))
        }
    }
}
